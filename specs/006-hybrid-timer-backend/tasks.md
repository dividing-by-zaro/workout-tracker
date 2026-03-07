# Tasks: Hybrid Rest Timer with Backend

**Input**: Design documents from `/specs/006-hybrid-timer-backend/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization — Xcode capabilities and backend project scaffolding

- [x] T001 Add Push Notifications capability and `aps-environment` entitlement in Kiln/Kiln.entitlements
- [x] T002 Add `remote-notification` to `UIBackgroundModes` in project.yml and Kiln/Info.plist
- [ ] T003 [P] Initialize backend project: run `uv init` in timer-backend/, add dependencies (fastapi, uvicorn, httpx, pyjwt, cryptography) via `uv add`, create .env.example with APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH, API_KEY, APNS_ENVIRONMENT placeholders in timer-backend/.env.example

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core services that multiple user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create NotificationService in Kiln/Services/NotificationService.swift — `@MainActor` class with: `requestPermission()` (calls `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])`), `scheduleRestTimer(duration:)` (creates `UNTimeIntervalNotificationTrigger`, uses `alert_tone.caf` as custom sound, identifier `"restTimer"`), `cancelRestTimer()` (calls `removePendingNotificationRequests(withIdentifiers: ["restTimer"])`)
- [x] T005 Request notification permission on app launch in Kiln/KilnApp.swift — call `NotificationService.requestPermission()` in `.onAppear` and set up `UNUserNotificationCenterDelegate` to handle foreground notification suppression (return empty presentation options in `willPresent`, let the existing in-app alert handle foreground expiry)

**Checkpoint**: Foundation ready — notification infrastructure is in place for US1

---

## Phase 3: User Story 1 - Reliable Rest Timer Alert (Priority: P1) MVP

**Goal**: Local notifications guarantee the rest timer alert fires reliably regardless of app state

**Independent Test**: Complete a set, lock the phone, wait 2 minutes. Verify a notification alert fires with sound on the lock screen.

### Implementation for User Story 1

- [x] T006 [US1] Integrate NotificationService into WorkoutSessionManager in Kiln/Services/WorkoutSessionManager.swift — add `let notificationService = NotificationService()` property; in `completeSet()` after `restTimer.start(duration:)`, call `notificationService.scheduleRestTimer(duration:)`
- [x] T007 [US1] Cancel local notification on timer skip/stop in Kiln/Services/WorkoutSessionManager.swift — call `notificationService.cancelRestTimer()` in `skipRestTimerInternal()`, `finishWorkout()`, `discardWorkout()`, `removeExercise()` (when timer set is in removed exercise), and `completeSet()` when uncompleting a set that has the active timer
- [x] T008 [US1] Handle foreground timer expiry with dual-path alert in Kiln/Services/WorkoutSessionManager.swift — in `handleTimerExpired()`, keep the existing `backgroundAudio.playAlertSound()` call for foreground alert tone; the local notification handles background/locked alert via its custom sound. Cancel the delivered notification after handling in foreground to avoid duplicate alerts.
- [x] T009 [US1] Cancel local notification when a new set is completed while a timer is already running in Kiln/Services/WorkoutSessionManager.swift — the `completeSet()` method already calls `restTimer.stop()` via `start()` internally, ensure `notificationService.cancelRestTimer()` is called before scheduling the new one (the schedule call in T006 handles the new notification)

**Checkpoint**: US1 complete. Rest timer alerts fire reliably via local notifications in all app states. Test by completing a set, locking phone, waiting for expiry.

---

## Phase 4: User Story 3 - Backend Timer Scheduling (Priority: P2)

**Goal**: Build the Coolify-hosted FastAPI backend that schedules delayed APNS pushes

**Independent Test**: POST to /timer/schedule with a push token and 10s duration; verify APNS push is sent after 10 seconds.

**Note**: US3 is implemented before US2 because the backend must exist before the iOS app can integrate with it.

### Implementation for User Story 3

- [ ] T010 [P] [US3] Implement APNS module in timer-backend/apns.py — create `APNSClient` class with: `__init__(key_path, key_id, team_id)` that reads the .p8 key file; `generate_jwt()` that creates ES256-signed JWT with `iss=team_id`, `iat=now` using PyJWT; `send_live_activity_update(push_token, content_state, alert)` that constructs the APNS payload with `event: "update"`, `timestamp`, `content-state`, and `alert` fields, sends via `httpx.AsyncClient` over HTTP/2 to `api.push.apple.com` with headers `apns-push-type: liveactivity`, `apns-topic: app.izaro.kiln.push-type.liveactivity`, `apns-priority: 10`. Cache JWT for reuse (valid 1 hour).
- [ ] T011 [P] [US3] Implement FastAPI app in timer-backend/main.py — create FastAPI app with: API key middleware (validate `Authorization: Bearer <key>` against `API_KEY` env var); `POST /api/timer/schedule` endpoint accepting `{push_token, duration_seconds, content_state, device_id}`, stores `PendingTimer` in `dict[str, PendingTimer]` keyed by `device_id`, cancels existing timer for same device_id if present, creates `asyncio.create_task()` that sleeps `duration_seconds` then calls `APNSClient.send_live_activity_update()`, returns `{"status": "scheduled", "fire_at": <iso_datetime>}`; `POST /api/timer/cancel` endpoint accepting `{device_id}`, cancels the asyncio task and removes from dict, returns `{"status": "cancelled"}` or `{"status": "no_pending_timer"}`; health check `GET /health`. Use lifespan context manager for APNSClient initialization.
- [ ] T012 [US3] Create Dockerfile in timer-backend/Dockerfile — multi-stage build: stage 1 uses `python:3.12-slim`, installs uv, copies `pyproject.toml` and `uv.lock`, runs `uv sync --frozen --no-cache`; stage 2 copies `.venv` from stage 1 and app source, sets `PATH` to include `.venv/bin`, exposes port 8000, CMD `["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]`

**Checkpoint**: Backend is deployable and testable independently. Can be tested locally with `uv run uvicorn main:app` and curl commands against /api/timer/schedule and /api/timer/cancel.

---

## Phase 5: User Story 2 - Live Activity Transitions on Timer Expiry (Priority: P1)

**Goal**: APNS push from backend updates the Live Activity from timer view to next set view when the app is backgrounded/locked

**Independent Test**: Complete a set from lock screen, wait for timer expiry, verify Live Activity automatically transitions to next set view without opening the app.

**Depends on**: US3 (backend must be running)

### Implementation for User Story 2

- [ ] T013 [US2] Enable push-to-update on Live Activity in Kiln/Services/LiveActivityService.swift — change `pushType: nil` to `pushType: .token` in `startActivity()` method (line 20). Add a new method `observePushToken(activity:completion:)` that iterates `activity.pushTokenUpdates` async sequence and calls the completion handler with the hex-encoded token string.
- [ ] T014 [US2] Create TimerBackendService in Kiln/Services/TimerBackendService.swift — `@MainActor` class with: configurable `baseURL` and `apiKey` (read from UserDefaults or hardcoded for MVP); `scheduleTimer(pushToken:duration:contentState:deviceId:)` async method that POSTs to `/api/timer/schedule` with JSON body per contracts/timer-api.md, fire-and-forget with error logging (no throw — graceful degradation); `cancelTimer(deviceId:)` async method that POSTs to `/api/timer/cancel`; use `URLSession` for HTTP requests (no external dependency needed).
- [ ] T015 [US2] Store and observe push token in Kiln/Services/WorkoutSessionManager.swift — add `private var currentPushToken: String?` and `let timerBackend = TimerBackendService()` properties. In `startLiveActivity()`, after creating the activity, call `liveActivityService.observePushToken(activity:)` and store the token in `currentPushToken`. In `reconnectLiveActivity()`, also observe the push token.
- [ ] T016 [US2] Send timer schedule to backend on set completion in Kiln/Services/WorkoutSessionManager.swift — in `completeSet()` and `completeCurrentSetFromIntent()`, after starting the rest timer and scheduling the local notification, build the next-set `ContentState` (with `isRestTimerActive: false`) and call `timerBackend.scheduleTimer(pushToken: currentPushToken, duration: restDuration, contentState: nextSetState, deviceId: deviceId)`. Use `UIDevice.current.identifierForVendor?.uuidString` as `deviceId`.
- [ ] T017 [US2] Send timer cancellation to backend on skip/finish in Kiln/Services/WorkoutSessionManager.swift — in `skipRestTimerInternal()`, `finishWorkout()`, and `discardWorkout()`, call `timerBackend.cancelTimer(deviceId:)` alongside the local notification cancellation

**Checkpoint**: US2 complete. Live Activity transitions automatically via APNS push when timer expires while app is backgrounded. Test by completing set, locking phone, waiting for timer, verifying Live Activity shows next set.

---

## Phase 6: User Story 4 - Remove Silent Audio Dependency (Priority: P3)

**Goal**: Remove the silent audio background workaround now that local notifications and APNS push handle timer reliability

**Independent Test**: Start a workout, complete a set, background the app, check Control Center — no "Now Playing" widget. Wait for timer, verify notification fires and Live Activity transitions.

**Depends on**: US1 + US2 (both must be verified working before removing the fallback)

### Implementation for User Story 4

- [ ] T018 [US4] Remove silent audio methods from Kiln/Services/BackgroundAudioService.swift — delete `startSilentAudio()`, `stopSilentAudio()`, the `audioPlayer` property, and the `isPlaying` property. Keep `playAlertSound()` and `alertPlayer` for foreground alert tone. Rename class to `AlertSoundService` or keep name (either is fine).
- [ ] T019 [US4] Remove all `backgroundAudio.startSilentAudio()` and `backgroundAudio.stopSilentAudio()` calls from Kiln/Services/WorkoutSessionManager.swift — remove calls in `startWorkout()` (line 125), `startEmptyWorkout()` (line 142), `resumeInterruptedWorkout()` (line 80), `handleForegroundResume()` (lines 604-606), `finishWorkout()` (line 308), `discardWorkout()` (line 325), and `reset()` (line 244)
- [ ] T020 [US4] Remove background task scheduling from Kiln/Services/WorkoutSessionManager.swift — delete `scheduleBackgroundRestExpiry()`, `cancelBackgroundRestExpiry()`, `endBackgroundTask()` methods and the `backgroundTaskId` and `restExpiryWorkItem` properties. Remove all calls to `scheduleBackgroundRestExpiry()` in `completeSet()` and `completeCurrentSetFromIntent()`, and all calls to `cancelBackgroundRestExpiry()` in `skipRestTimerInternal()`, `finishWorkout()`, `discardWorkout()`, `removeExercise()`, and `completeSet()` (uncomplete path).
- [ ] T021 [US4] Remove `audio` from `UIBackgroundModes` in project.yml and Kiln/Info.plist — keep only `remote-notification` (added in T002). Note: test that foreground `playAlertSound()` still works without the audio background mode; if it doesn't, keep `audio` mode.

**Checkpoint**: US4 complete. No silent audio, no background tasks. Timer reliability is fully handled by local notifications + APNS push. Verify full workout flow end-to-end.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and documentation

- [ ] T022 [P] Update CLAUDE.md with new architecture: document NotificationService, TimerBackendService, pushType: .token on Live Activity, removal of silent audio hack, backend URL/API key configuration, and new `remote-notification` background mode
- [ ] T023 [P] Run `xcodegen generate` to regenerate Kiln.xcodeproj after all file additions/removals (NotificationService.swift, TimerBackendService.swift, BackgroundAudioService changes)
- [ ] T024 Validate quickstart.md scenarios end-to-end: start workout → complete set → lock phone → verify notification fires with sound → verify Live Activity transitions to next set → skip timer → verify cancellation → finish workout

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — can start immediately after foundation
- **US3 (Phase 4)**: Depends on Phase 1 only (backend setup) — can run in PARALLEL with US1
- **US2 (Phase 5)**: Depends on US3 (backend must exist) + Phase 2 (iOS foundation)
- **US4 (Phase 6)**: Depends on US1 + US2 being verified working
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ├──→ Phase 2 (Foundation) ──→ Phase 3 (US1: Local Notifications)
    │                                    │
    │                                    ├──→ Phase 6 (US4: Remove Silent Audio)
    │                                    │           ↑
    └──→ Phase 4 (US3: Backend) ──→ Phase 5 (US2: Live Activity Push) ──┘
                                                    │
                                                    └──→ Phase 7 (Polish)
```

### Parallel Opportunities

- **T001 + T003**: Xcode capabilities and backend init can run in parallel
- **T010 + T011**: APNS module and FastAPI app are independent files
- **US1 (Phase 3) + US3 (Phase 4)**: iOS notification work and backend work are fully independent — can run in parallel
- **T022 + T023**: CLAUDE.md update and xcodegen are independent

### Within Each User Story

- Services before integration
- Core implementation before cleanup
- Story complete before moving to next priority

---

## Parallel Example: US1 + US3

```bash
# These two phases can run in parallel since they touch completely different codebases:

# Stream 1 (iOS): US1 - Local Notifications
Task: T006 — Integrate NotificationService into WorkoutSessionManager
Task: T007 — Cancel local notification on skip/stop
Task: T008 — Handle foreground timer expiry
Task: T009 — Cancel on new set completion

# Stream 2 (Backend): US3 - Backend Timer Scheduling
Task: T010 — Implement APNS module in timer-backend/apns.py
Task: T011 — Implement FastAPI app in timer-backend/main.py
Task: T012 — Create Dockerfile
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T005)
3. Complete Phase 3: US1 - Local Notifications (T006-T009)
4. **STOP and VALIDATE**: Test that notifications fire reliably in all app states
5. This alone fixes the alert reliability problem — deployable MVP

### Incremental Delivery

1. Setup + Foundation → Notification infrastructure ready
2. US1 (Local Notifications) → Alert fires reliably (MVP!)
3. US3 (Backend) → Timer backend deployed on Coolify
4. US2 (Live Activity Push) → Live Activity transitions automatically
5. US4 (Remove Silent Audio) → Clean up legacy workaround
6. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US1 is independently valuable — fixes alert reliability without backend
- US3 must be deployed before US2 can be tested end-to-end
- US4 should only be done after US1 + US2 are verified — it removes the safety net
- The backend is a separate codebase (timer-backend/) and can be developed/deployed independently
- No test tasks generated (not requested in spec)
