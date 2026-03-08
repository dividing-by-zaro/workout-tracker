# Tasks: User Authentication & Profiles

**Input**: Design documents from `/specs/007-user-auth/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/auth-api.md, quickstart.md

**Tests**: No test tasks generated (not requested in spec).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Exact file paths included in all descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add MongoDB dependency to backend, create new iOS service files

- [x] T001 Add `motor` dependency to `timer-backend/pyproject.toml` via `uv add motor`
- [x] T002 Add `MONGODB_URL` to `timer-backend/.env.example` with placeholder value
- [x] T003 Update `timer-backend/Dockerfile` to copy `db.py` alongside `main.py` and `apns.py`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: MongoDB connection, user seeding, per-user auth middleware, Keychain service — all stories depend on these

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create `timer-backend/db.py` with MongoDB client initialization (`motor.motor_asyncio.AsyncIOMotorClient`), `get_db()` helper, and `seed_users()` function that inserts 2 user documents (Isabel + Neta) with `kiln_`-prefixed API keys if `users` collection is empty. Print generated keys to stdout on seed.
- [x] T005 Update `timer-backend/main.py` lifespan to connect to MongoDB on startup (call `seed_users()`) and close client on shutdown. Add `db` reference accessible to routes.
- [x] T006 Update auth middleware in `timer-backend/main.py` to look up API key in MongoDB `users` collection instead of comparing against `API_KEY` env var. Attach matched user document to `request.state.user`. Return 401 if key not found. Keep `/health` exempt.
- [x] T007 Create `Kiln/Services/KeychainService.swift` — static methods: `save(key:value:)`, `load(key:) -> String?`, `delete(key:)` using Security framework (`SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete`). Service name: `app.izaro.kiln`, account: `api-key`.
- [x] T008 Create `Kiln/Services/AuthService.swift` — `@MainActor @Observable` class with auth state enum (`.checking`, `.unauthenticated`, `.authenticating`, `.authenticated(name: String)`). Properties: `userName: String?`, `errorMessage: String?`. Methods: `checkStoredAuth()` (reads Keychain, validates with backend, falls back to cached profile), `login(apiKey:)` (validates key via `GET /api/me`, stores in Keychain, caches profile in UserDefaults), `logout()` (clears Keychain + UserDefaults cache). Read backend URL from `Bundle.main` Info.plist `TimerBackendURL`.

**Checkpoint**: Backend serves authenticated requests with per-user keys. iOS has auth infrastructure ready.

---

## Phase 3: User Story 1 — First Launch API Key Entry (Priority: P1) MVP

**Goal**: User sees branded login screen on first launch, pastes API key, taps Connect, app validates and transitions to main view.

**Independent Test**: Launch app with no Keychain entry → login screen appears → paste valid key → tap Connect → main tab view appears. Repeat with invalid key → error shown.

### Implementation for User Story 1

- [x] T009 [US1] Create `Kiln/Views/LoginView.swift` — full-screen branded login view using DesignSystem tokens: warm cream `.grainedBackground()`, centered Kiln branding (flame icon `flame.fill` in `DesignSystem.Colors.primary`, "Kiln" title in `DesignSystem.Typography.title`), subtitle instruction text ("Enter your API key to get started"), `SecureField` or `TextField` for API key input with `.textContentType(.password)`, "Connect" primary button (fire red background, white text, `DesignSystem.CornerRadius.button`), error message text in `DesignSystem.Colors.destructive`, loading state on Connect button. Reads `AuthService` from environment, calls `authService.login(apiKey:)` on Connect.
- [x] T010 [US1] Update `Kiln/KilnApp.swift` — add `@State private var authService = AuthService()`, inject via `.environment(authService)`. Replace `ContentView()` with conditional: if `authService.isAuthenticated` show `ContentView()` else show `LoginView()`. Call `authService.checkStoredAuth()` in `.onAppear`.
- [x] T011 [US1] Add `GET /api/me` endpoint in `timer-backend/main.py` — returns `{"name": user["name"], "created_at": user["created_at"]}` from `request.state.user` (populated by auth middleware). Exclude `_id` and `api_key` from response. Serialize `created_at` as ISO 8601 string.

**Checkpoint**: Login flow works end-to-end. Valid key → app. Invalid key → error. Empty field → disabled button.

---

## Phase 4: User Story 2 — Persistent Authentication Across Launches (Priority: P1)

**Goal**: After initial login, app launches directly to main view using stored Keychain credential.

**Independent Test**: Log in successfully → force-quit app → relaunch → main tab view appears without login screen. Kill backend → relaunch → still works (cached profile).

### Implementation for User Story 2

- [x] T012 [US2] Implement `checkStoredAuth()` in `Kiln/Services/AuthService.swift` — on app launch: read API key from Keychain via `KeychainService.load(key: "api-key")`. If key exists, set state to `.checking`, attempt `GET /api/me` with stored key. On success: cache profile in UserDefaults (`cachedUserName`, `cachedUserProfileAt`), set state to `.authenticated`. On network failure: read cached profile from UserDefaults, set state to `.authenticated` if cache exists. On 401 response: clear Keychain + cache, set state to `.unauthenticated`.
- [x] T013 [US2] Update `Kiln/Services/TimerBackendService.swift` — replace `apiKey` property (currently read from `Bundle.main` Info.plist) with a read from `KeychainService.load(key: "api-key")` on each request. Remove `TimerBackendAPIKey` Info.plist dependency. Keep `baseURL` from Info.plist `TimerBackendURL`.

**Checkpoint**: Auth persists across restarts. Offline launch works with cached profile. Revoked key returns to login.

---

## Phase 5: User Story 3 — User Profile Display (Priority: P2)

**Goal**: Authenticated user sees their name in the Profile tab, fetched from backend.

**Independent Test**: Log in → navigate to Profile tab → user's name displayed instead of hardcoded "Isabel".

### Implementation for User Story 3

- [x] T014 [US3] Update `Kiln/Views/Profile/ProfileView.swift` — replace hardcoded `Text("Isabel")` with `Text(authService.userName ?? "User")`. Read `AuthService` from environment via `@Environment(AuthService.self)`.

**Checkpoint**: Profile tab shows authenticated user's name.

---

## Phase 6: User Story 4 — Logout (Priority: P3)

**Goal**: User can log out from Profile tab, clearing credentials and returning to login screen.

**Independent Test**: While authenticated → Profile tab → tap Logout → confirm → login screen appears → relaunch → login screen still shows.

### Implementation for User Story 4

- [x] T015 [US4] Add logout button and confirmation in `Kiln/Views/Profile/ProfileView.swift` — add a "Log Out" button (styled like existing "Delete All Data" button but with `DesignSystem.Colors.textSecondary` tint). On tap, show `.alert` confirmation ("Log out of Kiln?"). If workout in progress (`sessionManager.activeWorkout != nil`), warn "Your active workout will be lost." On confirm, call `authService.logout()`.
- [x] T016 [US4] Implement `logout()` in `Kiln/Services/AuthService.swift` — call `KeychainService.delete(key: "api-key")`, remove `cachedUserName` and `cachedUserProfileAt` from UserDefaults, set state to `.unauthenticated`. If workout in progress, call `sessionManager.reset()` before clearing auth (requires `WorkoutSessionManager` reference or delegation).

**Checkpoint**: Logout clears all credentials. Relaunch shows login. Active workout warning works.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, config updates, constitution amendment

- [x] T017 Remove `TIMER_BACKEND_API_KEY` from `Secrets.xcconfig`, `Secrets.xcconfig.example`, and `project.yml` Info.plist properties (no longer needed — API key comes from Keychain at runtime, not build time)
- [x] T018 [P] Update `project.yml` to remove `TimerBackendAPIKey` from Info.plist properties under both Kiln and KilnWidgets targets. Run `xcodegen generate`.
- [x] T019 [P] Update `.specify/memory/constitution.md` Principle VI — rename from "Single-User Simplicity" to "Household Simplicity". Change "exactly one user" to "exactly two users (household members)". Remove "backend MUST NOT implement user tables". Keep the spirit: no RBAC, no signup, no general multi-tenancy.
- [x] T020 Update `CLAUDE.md` — add `AuthService` to Services list, add `LoginView` to Views list, add MongoDB to Active Technologies, document Keychain storage pattern, update Key Decisions to reflect 2-user auth.
- [x] T021 Run quickstart.md validation — verify all setup steps from `specs/007-user-auth/quickstart.md` work end-to-end (backend seed, login, persistence, logout)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — first story, creates login flow
- **US2 (Phase 4)**: Depends on Phase 2 + T008 (AuthService exists) — persistence logic
- **US3 (Phase 5)**: Depends on Phase 2 + T008 (AuthService exists) — profile display
- **US4 (Phase 6)**: Depends on US1 + US3 (needs login screen + profile view to exist)
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: After Foundational → independently testable
- **US2 (P1)**: After Foundational → independently testable (uses same AuthService as US1)
- **US3 (P2)**: After Foundational → independently testable
- **US4 (P3)**: Depends on US1 (login screen to return to) and US3 (profile view for logout button)

### Within Each User Story

- Backend endpoints before iOS views that call them
- Services before views that consume them
- Core auth flow before edge cases

### Parallel Opportunities

- T001, T002, T003 can all run in parallel (Setup)
- T004 + T007 can run in parallel (backend DB + iOS Keychain — different codebases)
- T009 + T011 can run in parallel (login view + backend endpoint — different codebases)
- T017, T018, T019 can run in parallel (Polish cleanup)

---

## Parallel Example: Foundational Phase

```bash
# Backend and iOS foundational work can run in parallel:
Agent 1 (backend): T004 → T005 → T006 (sequential — DB setup → lifespan → middleware)
Agent 2 (iOS):     T007 → T008 (sequential — Keychain → AuthService)
```

## Parallel Example: User Story 1

```bash
# Backend endpoint and iOS view can run in parallel:
Agent 1 (backend): T011 (GET /api/me endpoint)
Agent 2 (iOS):     T009 (LoginView) → T010 (KilnApp auth gate)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T008)
3. Complete Phase 3: User Story 1 (T009–T011)
4. **STOP and VALIDATE**: Paste API key → login → see main app. Invalid key → error.
5. This is a functional MVP — app is gated behind auth.

### Incremental Delivery

1. Setup + Foundational → Backend serves per-user auth, iOS has Keychain + AuthService
2. US1 → Login screen works end-to-end (MVP!)
3. US2 → Auth persists across restarts, offline-tolerant
4. US3 → Profile shows user name
5. US4 → Logout works
6. Polish → Config cleanup, constitution update, CLAUDE.md update

---

## Notes

- No test tasks generated — testing is manual (Xcode build + curl)
- Backend changes are small (1 new file, 2 modified) — most work is iOS
- The `TimerBackendAPIKey` removal (T017–T018) means the build-time shared key is fully replaced by per-user runtime keys
- Constitution Principle VI amendment (T019) should happen during implementation to keep docs in sync
