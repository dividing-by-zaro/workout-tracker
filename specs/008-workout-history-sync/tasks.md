# Tasks: Workout History Sync

**Input**: Design documents from `/specs/008-workout-history-sync/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/sync-api.md

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Backend data models and database indexes needed by all sync endpoints

- [x] T001 [P] Create Pydantic models (WorkoutSetPayload, WorkoutExercisePayload, WorkoutPayload, WorkoutResponse, SyncStatusResponse) for the sync API in timer-backend/models.py — see contracts/sync-api.md for exact field definitions
- [x] T002 [P] Add MongoDB index creation for `exercises` collection (`user_id` + `name` unique compound) and `workouts` collection (`user_id` + `local_id` unique compound) in timer-backend/db.py — add to existing `seed_users()` or a new `ensure_indexes()` called at startup

---

## Phase 2: Foundational (Backend API)

**Purpose**: Server endpoints that MUST exist before any iOS sync code can work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Implement `POST /api/workouts` endpoint in timer-backend/main.py — accept WorkoutPayload, upsert each exercise into `exercises` collection (matched by `user_id` + `exercise_name`), insert workout into `workouts` collection with dedup check on `(user_id, local_id)` unique index, return 201 "created" or 200 "exists" per contracts/sync-api.md
- [x] T004 [P] Implement `GET /api/workouts/status` endpoint in timer-backend/main.py — count documents in `workouts` collection for the authenticated user, return `{"synced_count": N}` per contracts/sync-api.md

**Checkpoint**: Backend API ready — can test with curl per quickstart.md

---

## Phase 3: User Story 1 — Initial Full History Sync (Priority: P1) 🎯 MVP

**Goal**: On app launch, upload all completed local workouts to the server. Subsequent launches skip already-synced workouts.

**Independent Test**: Log in on a device with existing workout history → verify all workouts appear in MongoDB `workouts` collection → force-quit and relaunch → verify no duplicates created.

### Implementation for User Story 1

- [x] T005 [US1] Create `WorkoutSyncService` (`@MainActor @Observable`) in Kiln/Services/WorkoutSyncService.swift — include: (1) `baseURL` from Info.plist and `apiKey` from Keychain (same pattern as TimerBackendService), (2) `syncedWorkoutIds: Set<String>` loaded from/saved to UserDefaults key `syncedWorkoutIds`, (3) private `uploadWorkout(_ workout: Workout) async -> Bool` that serializes a Workout (with its sorted exercises and sets) to the WorkoutPayload JSON structure and POSTs to `/api/workouts`, returning true on 200/201 and marking the workout ID in syncedWorkoutIds, (4) `syncAllPending(context: ModelContext) async` that fetches all completed workouts (`isInProgress == false`), filters out those in syncedWorkoutIds, and uploads each sequentially, (5) `isSyncing: Bool` observable property
- [x] T006 [US1] Inject `WorkoutSyncService` into SwiftUI environment in Kiln/KilnApp.swift — create as `@State private var syncService = WorkoutSyncService()`, pass via `.environment(syncService)`, and add a `.task` modifier (or extend the existing auth-check task) that calls `syncService.syncAllPending(context:)` after `authService.state == .authenticated`

**Checkpoint**: All existing workout history syncs to server on launch. Relaunch creates no duplicates.

---

## Phase 4: User Story 2 — Automatic Sync on Workout Completion (Priority: P1)

**Goal**: When a user finishes a workout, it is immediately uploaded to the server in the background without any user action.

**Independent Test**: Complete a workout → check MongoDB within 5 seconds → workout document exists with correct exercises and sets.

### Implementation for User Story 2

- [x] T007 [US2] Add `WorkoutSyncService` dependency to `WorkoutSessionManager` and call `syncService.uploadWorkout()` from `finishWorkout(context:)` in Kiln/Services/WorkoutSessionManager.swift — fire-and-forget via `Task { await syncService.uploadWorkout(workout) }` after the workout is saved to SwiftData. Pass the sync service via environment or init parameter (match existing service injection pattern).

**Checkpoint**: Finishing a workout immediately syncs it to the server. Offline completions are caught by the US1 launch sync.

---

## Phase 5: User Story 3 — Sync Status Visibility (Priority: P2)

**Goal**: The Profile screen shows whether all workouts are backed up or how many are pending sync.

**Independent Test**: View Profile with all workouts synced → see "All workouts backed up" indicator. Complete a workout while offline → view Profile → see "1 workout pending sync".

### Implementation for User Story 3

- [x] T008 [P] [US3] Add `syncedCount: Int` (computed from `syncedWorkoutIds.count`) and `pendingCount: Int` (requires total completed workout count passed in or fetched) observable properties to Kiln/Services/WorkoutSyncService.swift — also add `fetchServerSyncCount() async` that calls `GET /api/workouts/status` and stores the result for display
- [x] T009 [US3] Add sync status section to Kiln/Views/Profile/ProfileView.swift — display between the chart and the Import button: show "All workouts backed up" with a checkmark icon when `pendingCount == 0`, or "N workouts pending sync" with a cloud icon when pending. Use existing DesignSystem colors and typography. Read `WorkoutSyncService` from environment.

**Checkpoint**: Profile screen accurately reflects sync state.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and project file updates

- [x] T010 Run `xcodegen generate` to include new Kiln/Services/WorkoutSyncService.swift in the Xcode project
- [x] T011 Update CLAUDE.md — add WorkoutSyncService to the Services list, document sync architecture (one-directional device→server, UserDefaults sync state, POST /api/workouts endpoint), add `models.py` to timer-backend structure, update Active Technologies if needed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 models used by T003/T004)
- **US1 (Phase 3)**: Depends on Phase 2 (backend must exist for iOS to upload)
- **US2 (Phase 4)**: Depends on Phase 3 (uses WorkoutSyncService created in T005)
- **US3 (Phase 5)**: Depends on Phase 2 (uses GET /api/workouts/status from T004) and Phase 3 (uses WorkoutSyncService)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Foundational only — this is the MVP
- **User Story 2 (P1)**: Depends on US1 (reuses WorkoutSyncService)
- **User Story 3 (P2)**: Depends on US1 (reuses WorkoutSyncService) + GET /api/workouts/status from Foundational

### Within Each User Story

- Backend endpoints before iOS service code
- Core service before integration hooks
- Service logic before UI

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T003 and T004 can run in parallel (different endpoints, same file but independent)
- T008 and T009 prep can overlap (different files)

---

## Parallel Example: Phase 1

```text
# Launch setup tasks together:
Task: "Create Pydantic models in timer-backend/models.py"
Task: "Add MongoDB indexes in timer-backend/db.py"
```

## Parallel Example: Phase 2

```text
# Launch backend endpoints together:
Task: "Implement POST /api/workouts in timer-backend/main.py"
Task: "Implement GET /api/workouts/status in timer-backend/main.py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: Foundational (T003, T004)
3. Complete Phase 3: User Story 1 (T005, T006)
4. **STOP and VALIDATE**: Launch app → verify all workouts sync to MongoDB → relaunch → verify no duplicates
5. Deploy backend changes to Coolify

### Incremental Delivery

1. Setup + Foundational → Backend API ready
2. Add User Story 1 → Test bulk sync → Deploy (MVP!)
3. Add User Story 2 → Test per-workout sync → Deploy
4. Add User Story 3 → Test profile indicator → Deploy
5. Polish → Update docs → Final deploy

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- WorkoutSyncService is the central new file — created in US1, extended in US2/US3
- Backend follows existing patterns: auth middleware, Pydantic models, motor async MongoDB
- iOS follows existing patterns: @MainActor @Observable service, environment injection, fire-and-forget network calls
- Commit after each phase or logical group
