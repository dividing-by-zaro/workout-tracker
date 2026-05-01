# 011 — CI/CD, Tests, and Reviewer Agent

## Context

Solo developer (Isabel) shipping Kiln, a 2-user iOS workout tracker (developer + wife). Backend is FastAPI + MongoDB on Coolify. iOS client is SwiftUI + SwiftData. Goal: let AI agents push code freely, with the human only stepping in when the reviewer agent flags either (a) a breaking bug / serious issue, or (b) a PR that doesn't match the app's intent or the issue's intent.

This spec is a corrected version of an earlier draft. Corrections include: real auth model (per-user API keys, not JWT), the existing `/health` endpoint, APNS lifespan handling in tests, iOS-side test coverage (which dominates user-facing risk in a local-first app), and explicit reviewer-agent scope.

---

## Part 0 — What already exists

Before writing anything new, the implementer (or implementing agent) must verify these against the codebase:

- `/health` endpoint exists in `timer-backend/main.py` — audit and harden, do not reimplement.
- Auth is **per-user API keys** stored in MongoDB `users` collection (see `db.py`, `AuthService.swift`, `KeychainService.swift`). There is no JWT, no password auth.
- Daily Google Drive backup exists in `timer-backend/backup.py` — assume working, do not retest in this scope.
- Glade exercise sync (`glade_sync.py`) is fire-and-forget; failures already log without blocking. Smoke tests must respect this.
- iOS app already has `Kiln.xcodeproj` regenerated from `project.yml` via `xcodegen`. CI builds must run `xcodegen generate` before invoking `xcodebuild`.
- `Kiln/Tests/` does not exist yet. iOS tests are net-new.
- `timer-backend/tests/` does not exist yet. Backend tests are net-new.

If any of these assumptions are wrong, stop and reconcile before continuing.

---

## Part 1 — Backend test suite

### Framework

- `pytest` with `pytest-asyncio` (`asyncio_mode = "auto"`).
- `httpx.AsyncClient` with `ASGITransport` for in-process API testing — no live server.
- **Real MongoDB via `testcontainers-python`** for all tests. No `mongomock`. The version pinned to whatever Coolify is running (verify via Coolify dashboard before pinning; default `mongo:7`).
- Managed by `uv` (`uv add --dev pytest pytest-asyncio httpx testcontainers`).

### Directory layout

```
timer-backend/
├── tests/
│   ├── conftest.py          # fixtures
│   ├── fixtures/            # canned response bodies used by both backend tests AND iOS decode tests
│   │   ├── workout_post.json
│   │   ├── workouts_ids.json
│   │   ├── me.json
│   │   └── ...
│   ├── test_auth.py
│   ├── test_workouts.py
│   ├── test_health.py
│   ├── test_indexes.py
│   └── smoke/
│       └── test_smoke.py
```

The `fixtures/` directory is the **single source of truth** for response shapes. Both backend contract tests and iOS Codable decode tests load from it. This is what makes the cross-language guardrail work.

### Required fixtures (`conftest.py`)

- `mongo_container`: session-scoped `testcontainers.mongodb.MongoDbContainer`, yields connection URL.
- `db`: function-scoped, returns a clean DB. Drops collections between tests.
- `app`: yields the FastAPI app with **APNS, Glade sync, and the backup scheduler stubbed out** via dependency overrides. `lifespan` startup must not attempt real connections to those services in tests. Do this by feature-flagging the lifespan via `KILN_TEST_MODE=1` env var, which short-circuits the startup tasks.
- `client`: `AsyncClient(transport=ASGITransport(app=app))`, base URL `http://test`.
- `test_user`: function-scoped, creates a user document with a known API key in the test DB and returns the key.
- `authed_client`: `client` with `Authorization: Bearer <test_user_key>` pre-applied. (Confirm header format matches what `AuthService` actually sends — read `TimerBackendService.swift` to verify.)

### Coverage requirements

For every endpoint the iOS app calls (audit `TimerBackendService.swift` and `WorkoutSyncService.swift` for the full list — at minimum: `/api/me`, `/api/workouts` POST/PUT/DELETE, `/api/workouts/ids`, `/api/workouts/status`, `/api/timer/schedule`, `/api/timer/cancel`, `/health`):

1. **Happy path** — valid request returns expected status and a body that matches the canned fixture in `tests/fixtures/`.
2. **Auth** — unauthenticated → 401. Authenticated as user A trying to access user B's data → 403.
3. **Validation** — malformed body → 422 with FastAPI's standard error structure.
4. **Not found** — nonexistent resource → 404.
5. **Persistence** — for any endpoint that writes, query MongoDB after the call and assert the document exists with the expected fields.

### Contract assertion

A single-level `isinstance` check is insufficient. Use Pydantic itself:

```python
from pydantic import TypeAdapter
from .models import WorkoutResponse  # the same model the endpoint returns

def test_post_workout_response_shape(authed_client, sample_workout_payload):
    r = await authed_client.post("/api/workouts", json=sample_workout_payload)
    assert r.status_code == 201
    # Round-trip through the Pydantic model — fails on missing fields, wrong types,
    # extra fields if model is configured strict, and nested shape errors.
    parsed = TypeAdapter(WorkoutResponse).validate_python(r.json())
    # Then snapshot-compare against the fixture for any drift in optional fields:
    assert r.json() == load_fixture("workout_post.json")
```

The fixture files are committed to the repo and updated **only** by an agent that explicitly notes "response shape changed — iOS decode tests must update."

### MongoDB-specific patterns

- ObjectId serialization: every response containing `_id` must serialize as a string.
- Index existence: write a `test_indexes.py` that asserts each expected index is present after `ensure_indexes()` runs.
- Aggregation pipelines: test against both empty and populated collections.
- Reconcile path (`GET /api/workouts/ids`): test that the device-truth model holds — a workout on the server but not in the request gets deleted; a workout in the request but not on the server gets uploaded. This is critical and currently has no test.

### What NOT to test

- FastAPI / Pydantic / motor internals.
- Glade sync end-to-end (it's fire-and-forget). Mock `glade_sync.send()` and assert it was called with the right shape.
- APNS push delivery. Mock `APNSClient.push()`.
- Backup upload to Google Drive. Skip entirely.
- Coverage percentages. Aim for **every iOS-facing endpoint covered with all 5 cases above**.

---

## Part 2 — iOS test suite

This is the part most likely to catch user-facing regressions, and was missing from the original spec. Two phases.

### Phase 1: Codable decode tests

**Goal:** catch backend → iOS contract drift before it reaches a device.

- New target: `KilnTests` (XCTest) under `Kiln/Tests/`. Add to `project.yml`.
- Copy `timer-backend/tests/fixtures/*.json` into the `KilnTests` bundle as resources. (Use a build script or symlink — the source of truth must remain the backend fixtures directory; do not maintain two copies by hand.)
- One test per response model:

```swift
final class WorkoutSyncContractTests: XCTestCase {
    func testWorkoutResponseDecodes() throws {
        let url = Bundle(for: type(of: self)).url(forResource: "workout_post", withExtension: "json")!
        let data = try Data(contentsOf: url)
        // The actual response model used by WorkoutSyncService:
        _ = try JSONDecoder.kilnBackend.decode(WorkoutResponse.self, from: data)
    }
}
```

- Cover every backend response type the app decodes: `WorkoutResponse`, `SyncStatusResponse`, the `/api/me` profile response, the workout-ids reconcile payload, etc.
- These tests are fast (milliseconds) and catch the failure mode where the backend renames or retypes a field and the iOS app crashes silently on next sync.

### Phase 2: SwiftData migration tests

**Goal:** catch the "wife's workout history is corrupted on next launch" failure mode.

- For each released schema version, commit a small `.store` file containing a representative DB to `Kiln/Tests/Migrations/Fixtures/`. (Generate by running the app once on the prior schema, exporting the SwiftData store.)
- A migration test loads each historical store and asserts:
  - `ModelContainer` opens cleanly under the current schema.
  - All workouts decode with no nil required fields.
  - Set counts, exercise counts, and total volume match a known-good snapshot.
- Add a new fixture snapshot every time the schema changes — making the test the forcing function for "did I think about migration?"

### Out of scope for v1

- UI tests (XCUITest).
- Snapshot tests on rendered views.
- Live Activity / WidgetKit tests (extension boundary makes these expensive; the existing Live Activity logic is tested manually via the device).
- Performance tests.

---

## Part 3 — GitHub Actions CI

Two workflows: backend tests and iOS tests. Run in parallel.

### `.github/workflows/test-backend.yml`

Triggers: `pull_request` to master, `push` to master, `workflow_dispatch`.

```yaml
jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      mongodb:
        image: mongo:7  # match production Coolify version
        ports: [27017:27017]
        options: >-
          --health-cmd "mongosh --eval 'db.adminCommand({ping:1})'"
          --health-interval 10s --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
        with:
          enable-cache: true
          cache-dependency-glob: timer-backend/uv.lock
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - working-directory: timer-backend
        run: uv sync --frozen --extra dev
      - working-directory: timer-backend
        env:
          KILN_TEST_MODE: "1"
          MONGO_URL: "mongodb://localhost:27017"
        run: uv run pytest --tb=short -v
      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: backend-test-results
          path: timer-backend/test-results.xml
```

### `.github/workflows/test-ios.yml`

Triggers: same as backend.

```yaml
jobs:
  ios:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: brew install xcodegen
      - run: xcodegen generate
      - name: Sync fixtures from backend
        run: cp timer-backend/tests/fixtures/*.json Kiln/Tests/Fixtures/
      - run: |
          xcodebuild test \
            -scheme Kiln \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:KilnTests \
            -resultBundlePath ios-test-results.xcresult
      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ios-test-results
          path: ios-test-results.xcresult
```

Notes on cost: `macos-15` runners are ~10× more expensive per minute than Linux. For solo-dev volume this is acceptable; revisit if PR volume grows.

### Branch protection (configured via GitHub UI)

- master requires PR.
- `backend` and `ios` checks must pass before merge.
- No direct pushes to master (this means future Isabel-direct commits also flow through PRs, which is fine).

---

## Part 4 — Coolify deployment gating

### Deploy workflow

`.github/workflows/deploy.yml` — triggers on `push` to master, depends on both `test-backend` and `test-ios` passing.

```yaml
jobs:
  deploy:
    needs: [backend, ios]  # if using a single workflow; otherwise wait via workflow_run
    runs-on: ubuntu-latest
    steps:
      - run: |
          curl -fsS -X POST "$COOLIFY_DEPLOY_WEBHOOK" \
               -H "Authorization: Bearer $COOLIFY_TOKEN"
        env:
          COOLIFY_DEPLOY_WEBHOOK: ${{ secrets.COOLIFY_DEPLOY_WEBHOOK }}
          COOLIFY_TOKEN: ${{ secrets.COOLIFY_TOKEN }}
```

### Coolify configuration (manual one-time)

- Disable auto-deploy-on-push for the `timer-backend` app.
- Health check: `GET /health`, expect 200, 30s timeout, 3 retries.
- Deployment strategy: Coolify default for single-replica apps is restart-in-place. **This is not real rolling.** During a deploy, the backend is unavailable for ~5–15s. For a 2-user app this is acceptable; document it rather than pretend otherwise. If true zero-downtime is later required, add a second replica behind Coolify's reverse proxy.

### `/health` endpoint requirements

The endpoint already exists. Audit it and, if it does not already do the following, modify it to:

- Ping MongoDB via `motor.AsyncIOMotorClient.admin.command("ping")` with a 1s timeout.
- Return 200 `{"status": "ok", "mongo": "connected"}` on success.
- Return 503 `{"status": "unhealthy", "mongo": "<error>"}` on failure.
- **Not** check Glade or APNS — those are fire-and-forget; their failure should not block deploys.

### In-flight timer state during deploy

`TimerBackendService` schedules in-memory `asyncio.sleep`-based timers. **A deploy drops all pending Live Activity push notifications.** This is an accepted limitation given the 2-user scale. Document it in CLAUDE.md and move on. (If it becomes a problem: persist scheduled timers to MongoDB on creation, replay on startup. Out of scope for v1.)

---

## Part 5 — Post-deploy smoke tests

`.github/workflows/smoke.yml` — `workflow_run` trigger on `deploy.yml` success.

### Steps

1. **Poll `/health` until healthy or 60s timeout.** Replaces the original spec's arbitrary 30s sleep.
2. Run `uv run pytest timer-backend/tests/smoke/ -v` against `$PROD_API_URL`.
3. On failure: `curl` the Coolify rollback webhook and post a comment to the most recent merged PR tagging Isabel.

### Smoke coverage

Smoke tests use a dedicated user — `SMOKE_TEST_USER` — provisioned once manually with a known API key stored as `SMOKE_TEST_API_KEY` (NOT email/password — the auth model is API key based). The smoke user's `local_id`s are namespaced (e.g. prefixed `smoke-`) so reads/writes never collide with real data.

Tests:
- `GET /health` → 200.
- `GET /api/me` with `SMOKE_TEST_API_KEY` → 200, profile shape valid.
- `GET /api/workouts/ids` → 200, returns a list.
- `POST /api/workouts` with an idempotent `local_id` like `smoke-workout-1` → succeeds and is replayable.
- **One Glade-touching write** if Glade env vars are configured for the smoke user. Don't fail the smoke run on Glade failure (it's fire-and-forget) — but do log it for human follow-up.

### Required secrets

GitHub Actions:
- `ANTHROPIC_API_KEY` (existing)
- `COOLIFY_DEPLOY_WEBHOOK`
- `COOLIFY_ROLLBACK_WEBHOOK`
- `COOLIFY_TOKEN`
- `PROD_API_URL`
- `SMOKE_TEST_API_KEY`

### Notification channel

Use a GitHub issue auto-created by the smoke workflow with `auto-rollback` label and `@dividing-by-zaro` mentioned. Rationale: you already use issues for everything; no need for Slack/Discord setup. The auto-triage workflow we just built will then RICE-score the rollback issue automatically.

---

## Part 6 — Migration safety

### MongoDB (low priority — backend is backup, not source of truth)

Adding fields: safe.
Removing fields: two-deploy.
Renaming: three-deploy expand-contract with backfill between deploys 1 and 2.
Type changes: never in place — add new field, migrate, remove old field.
Index changes: build in background, test in staging if collection is large.

`migrations/` directory with numbered idempotent Python scripts. Each script writes to a `migrations` collection on completion to track which have run; scripts must check this collection and exit early if already applied.

### SwiftData (HIGH priority — local source of truth)

This is the side that can corrupt user data on app update. Rules:

- Any change to a `@Model` class (new required field, removed field, renamed field, type change) requires:
  1. A SwiftData `VersionedSchema` declaration for the new version.
  2. A `MigrationStage` (custom or lightweight) defined in a new `MigrationPlan`.
  3. A new `.store` fixture committed under `Kiln/Tests/Migrations/Fixtures/v<N>/` representing the OLD schema.
  4. A migration test that loads the old store and verifies it opens under the new schema with no data loss.
- Optional fields and adding new entities are usually safe (lightweight migration).
- Renaming a field requires `MigrationStage.custom` and explicit data preservation — never trust the lightweight path here.
- Removing a required field is the riskiest operation; require Isabel review (see Part 8).

---

## Part 7 — Agent guardrails (CLAUDE.md additions)

Add a new section to the project's `CLAUDE.md`:

```markdown
## CI/CD invariants for AI agents

- All code changes require tests. New endpoint or new model = new test.
- Any change to a Pydantic response model on the backend MUST update both:
  (a) the corresponding fixture in `timer-backend/tests/fixtures/`, AND
  (b) the iOS Codable model that decodes it.
  These two MUST be updated in the same PR.
- Any change to a SwiftData @Model requires a new schema version, migration plan,
  and a Phase 2 migration test. See specs/011-cicd/spec.md Part 6.
- Never delete or skip tests to make CI pass. Fix the test or the code.
- Never commit secrets. Use `.env.example` and `Secrets.xcconfig.example`.
- Never modify `tests/smoke/` casually. If a smoke test legitimately needs an
  update, call it out explicitly in the PR description.
- The backend `/api/timer/schedule` keeps timers in memory. Do not assume timers
  survive a deploy.
```

These are statements of intent. Enforcement happens via the reviewer agent, not via the rules themselves.

---

## Part 8 — Reviewer agent

Separate workflow, separate prompt, separate model context.

### Workflow

`.github/workflows/review-pr.yml`

```yaml
name: Review PR
on:
  pull_request:
    types: [opened, synchronize, ready_for_review]

permissions:
  contents: read
  pull-requests: write
  issues: write
  id-token: write

jobs:
  review:
    if: github.event.pull_request.user.login != 'dividing-by-zaro'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_args: |
            --max-turns 30
            --allowedTools "Bash(gh:*),Bash(git log:*),Bash(git diff:*),Bash(git show:*),Read,Glob,Grep"
          prompt: |
            You are reviewing PR #${{ github.event.pull_request.number }} on the
            Kiln iOS workout-tracking app. This is a 2-user personal app.

            Your job is narrow: decide whether to APPROVE-AND-MERGE, or to REQUEST
            CHANGES and tag @dividing-by-zaro for human review.

            Tag Isabel ONLY if you find one of:
              1. A breaking bug, regression, or serious correctness/security issue.
                 Examples: deleted or skipped tests, weakened auth, secrets leaked,
                 SwiftData @Model changed without a migration, response shape
                 changed without iOS contract test updated, obvious crash path,
                 IDOR / wrong-user data access.
              2. The PR doesn't match the intent of the linked issue, or is out
                 of scope for the app per CLAUDE.md.

            Otherwise — APPROVE AND MERGE. Isabel trusts well-written code; do
            not tag her for style nits, minor refactors, or "this could be
            cleaner" observations.

            Workflow:
              1. gh pr view ${{ github.event.pull_request.number }}
              2. gh pr diff ${{ github.event.pull_request.number }}
              3. Read CLAUDE.md and the linked issue (if any).
              4. Check the diff against criteria 1 and 2 above.
              5. EITHER:
                 - gh pr review ${{ github.event.pull_request.number }} --approve --body "<short reason>"
                   then: gh pr merge ${{ github.event.pull_request.number }} --squash --auto
                 - OR: gh pr review ${{ github.event.pull_request.number }} --request-changes --body "<concrete reason>"
                   then: gh pr edit ${{ github.event.pull_request.number }} --add-assignee dividing-by-zaro

            Be decisive. Be terse in the review body. Do not lecture.
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Tag-Isabel criteria (codified)

A PR triggers human review if and only if the reviewer agent finds at least one of:

1. **Breaking / serious issue:**
   - Tests deleted, skipped, or weakened (`@pytest.mark.skip`, weakened assertions, removed contract checks).
   - Auth changed (any file under `Kiln/Services/Auth*`, `KeychainService`, `timer-backend/main.py` auth dependency, `db.py` user lookup).
   - Backend response shape changed without the corresponding iOS Codable model AND fixture both updated.
   - SwiftData `@Model` changed without a new `VersionedSchema` + migration test fixture in the same PR.
   - Secrets / API keys / tokens added to the diff.
   - Obvious crash, race, or unbounded loop introduced.
   - Wrong-user data access path (any user could read another user's data).

2. **Intent / scope mismatch:**
   - PR description doesn't match the linked issue, or no linked issue exists for non-trivial changes.
   - Adds a feature outside Kiln's scope per CLAUDE.md (e.g., social features, multi-user real-time sync, payment processing).
   - Removes an existing feature without an obvious reason.

Everything else: approve and merge.

### Self-review prevention

The `if: github.event.pull_request.user.login != 'dividing-by-zaro'` guard skips PRs Isabel opens herself — those flow through normally without auto-merge. PRs from other agents (`@claude` mention agent, future writer agents) are subject to review.

---

## Part 9 — Build order

Each step ends with "verify it works before moving on." Do not batch.

1. `/health` audit + harden + first backend test (asserts pings MongoDB, returns 503 when DB down).
2. Backend `conftest.py` fixtures + `KILN_TEST_MODE` lifespan flag + 2 example tests for `/api/me` (happy + unauth).
3. Backend test workflow (`test-backend.yml`). Verify it runs on a throwaway PR.
4. Fill in remaining backend endpoint tests + the `tests/fixtures/*.json` set.
5. iOS Phase 1: `KilnTests` target, fixture sync, decode tests for every backend response model. Verify locally with `xcodebuild test`.
6. iOS test workflow (`test-ios.yml`). Verify on a throwaway PR.
7. iOS Phase 2: `Kiln/Tests/Migrations/Fixtures/v<current>/` baseline `.store`, migration test scaffold (passes trivially today since v<current> = v<current>). The first real schema bump will exercise it.
8. Deploy workflow + Coolify webhook configuration (manual Coolify steps documented).
9. Smoke workflow + auto-rollback + auto-issue creation.
10. Migration safety docs + `migrations/` directory README + SwiftData migration playbook.
11. CLAUDE.md updates (Part 7).
12. Reviewer agent workflow (Part 8). Test on a throwaway PR.

---

## Deliverables

- [ ] `timer-backend/tests/conftest.py`
- [ ] `timer-backend/tests/fixtures/*.json`
- [ ] `timer-backend/tests/test_*.py`
- [ ] `timer-backend/tests/smoke/test_smoke.py`
- [ ] `timer-backend/pyproject.toml` updated with dev deps + pytest config
- [ ] `timer-backend/main.py` — `KILN_TEST_MODE` lifespan branch, audited `/health`
- [ ] `Kiln/Tests/` target wired in `project.yml`
- [ ] `Kiln/Tests/ContractTests/*.swift` — Phase 1
- [ ] `Kiln/Tests/Migrations/Fixtures/v<current>/` baseline + scaffolded test — Phase 2
- [ ] Build script or symlink syncing `timer-backend/tests/fixtures/` → `Kiln/Tests/Fixtures/`
- [ ] `.github/workflows/test-backend.yml`
- [ ] `.github/workflows/test-ios.yml`
- [ ] `.github/workflows/deploy.yml`
- [ ] `.github/workflows/smoke.yml`
- [ ] `.github/workflows/review-pr.yml`
- [ ] `migrations/` directory + README
- [ ] `CLAUDE.md` updates (Part 7)
- [ ] List of manual Coolify config changes (disable auto-deploy, set health check, retrieve webhook URLs)
- [ ] `README.md` section on running tests locally (`uv run pytest`, `xcodebuild test`)

---

## What this spec deliberately does not do

- Performance or load testing.
- iOS UI / snapshot tests.
- Multi-replica / true zero-downtime deploys.
- In-flight timer state persistence across restarts.
- Backups / disaster recovery (already covered by `backup.py`).
- Writer-agent setup. This spec assumes writer agents exist and produce PRs; it does not specify how they're invoked.
- Cost / budget alerts on Anthropic / Mongo / Coolify. Worth adding later but out of scope here.

---

## Risk register

| Risk | Severity | Mitigation in this spec |
|---|---|---|
| Backend response shape changes break iOS silently | High | Phase 1 Codable decode tests + shared fixtures |
| SwiftData migration corrupts user data | High | Phase 2 migration tests + Isabel-tagged review |
| Reviewer agent rubber-stamps a real bug | Medium | Conservative tag-Isabel criteria favor caution; weekly spot-check by Isabel |
| Reviewer agent over-tags Isabel (review fatigue) | Medium | Criteria are explicit and narrow; refine after 4 weeks of real usage |
| Coolify deploy mid-workout drops Live Activity timers | Low | Documented limitation; 2-user scale tolerates it |
| Smoke test false positive triggers rollback | Low | Auto-issue with details; Isabel can override |
| Agent deletes tests to land a PR | High → Low | Reviewer agent's #1 trigger criterion is "tests deleted/skipped" |
| Glade sync silently breaks post-deploy | Low | Smoke test logs but doesn't fail on Glade; rely on visible Glade staleness for detection |
