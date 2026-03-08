# Tasks: Workout Sync Updates

**Input**: Design documents from `/specs/009-workout-sync-updates/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/workout-sync-api.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Backend Endpoints)

**Purpose**: Add PUT and DELETE endpoints to the backend so the iOS client can update and remove workouts on the server. Both US1 and US2 depend on these endpoints.

**⚠️ CRITICAL**: No iOS sync work can begin until these endpoints exist.

- [x] T001 Add `PUT /api/workouts/{local_id}` endpoint to `timer-backend/main.py` — accept `WorkoutPayload` body, find existing workout by `(user_id, local_id)`, replace the document using `replace_one` (preserving `_id` and `user_id`), upsert exercise metadata (same as POST), update `synced_at` to current time, return `{"status": "updated", "local_id": "..."}` (200) or `{"error": "Workout not found"}` (404). See `specs/009-workout-sync-updates/contracts/workout-sync-api.md` for full contract.
- [x] T002 Add `DELETE /api/workouts/{local_id}` endpoint to `timer-backend/main.py` — find and delete workout by `(user_id, local_id)`, return `{"status": "deleted", "local_id": "..."}` (200) or `{"error": "Workout not found"}` (404). Do NOT delete exercise metadata. See `specs/009-workout-sync-updates/contracts/workout-sync-api.md` for full contract.

**Checkpoint**: Both endpoints can be tested with curl against a running backend before any iOS changes.

---

## Phase 2: User Story 1 — Edited Workout Syncs to Server (Priority: P1) 🎯 MVP

**Goal**: When a user edits a completed workout in the history view and dismisses the edit sheet, the updated workout is sent to the server.

**Independent Test**: Edit a previously synced workout's name or set data, then check MongoDB to verify the server record matches the updated local data.

### Implementation for User Story 1

- [x] T003 [US1] Add pending edit tracking and `updateWorkout()` to `Kiln/Services/WorkoutSyncService.swift` — add `pendingEditWorkoutIds: Set<String>` property persisted to UserDefaults key `"pendingEditWorkoutIds"` (same pattern as `syncedWorkoutIds`). Add `markWorkoutEdited(_ workout: Workout)` method: if `workout.id.uuidString` is in `syncedWorkoutIds`, insert into `pendingEditWorkoutIds`. Add `updateWorkout(_ workout: Workout) async -> Bool` method: build payload via existing `buildPayload(from:)`, send `PUT` to `/api/workouts/{local_id}` with Bearer auth, on 200 remove from `pendingEditWorkoutIds` and return true, on 404 remove from `pendingEditWorkoutIds` (workout doesn't exist on server, nothing to update) and return true, on network error return false.
- [x] T004 [US1] Wire WorkoutEditView dismiss to trigger edit sync in `Kiln/Views/History/WorkoutEditView.swift` — add `@Environment(WorkoutSessionManager.self) private var sessionManager` property. In the "Done" button action (after `modelContext.save()`), call `sessionManager.syncService.markWorkoutEdited(workout)` then fire-and-forget `Task { await sessionManager.syncService.updateWorkout(workout) }` before `dismiss()`.

**Checkpoint**: Edit a synced workout name → verify MongoDB document updated. Edit an unsynced workout → verify no network request sent.

---

## Phase 3: User Story 2 — Deleted Workout Removed from Server (Priority: P1)

**Goal**: When a user deletes a completed workout from the history view, the workout is also removed from the server.

**Independent Test**: Delete a previously synced workout, then check MongoDB to verify the record is gone and `GET /api/workouts/status` count decreased.

### Implementation for User Story 2

- [x] T005 [US2] Add pending delete tracking and `deleteWorkoutFromServer()` to `Kiln/Services/WorkoutSyncService.swift` — add `pendingDeleteWorkoutIds: Set<String>` property persisted to UserDefaults key `"pendingDeleteWorkoutIds"`. Add `markWorkoutDeleted(localId: String)` method: if `localId` is in `syncedWorkoutIds`, insert into `pendingDeleteWorkoutIds`, remove from `syncedWorkoutIds`, and remove from `pendingEditWorkoutIds` (delete supersedes edit per deduplication rule). If `localId` is NOT in `syncedWorkoutIds`, no-op (workout was never synced). Add `deleteWorkoutFromServer(localId: String) async -> Bool` method: send `DELETE` to `/api/workouts/{localId}` with Bearer auth, on 200 or 404 remove from `pendingDeleteWorkoutIds` and return true, on network error return false.
- [x] T006 [US2] Wire HistoryListView delete to trigger server deletion in `Kiln/Views/History/HistoryListView.swift` — add `@Environment(WorkoutSessionManager.self) private var sessionManager` property. In the delete confirmation button action, before `modelContext.delete(workout)`, capture `let localId = workout.id.uuidString`. After the delete and save, call `sessionManager.syncService.markWorkoutDeleted(localId: localId)` then fire-and-forget `Task { await sessionManager.syncService.deleteWorkoutFromServer(localId: localId) }`.

**Checkpoint**: Delete a synced workout → verify MongoDB record removed and server count decreased. Delete an unsynced workout → verify no network request sent.

---

## Phase 4: User Story 3 — Sync Resilience for Edits and Deletes (Priority: P2)

**Goal**: Failed edit and delete syncs are retried on next app launch, achieving eventual consistency.

**Independent Test**: Edit or delete a workout while in airplane mode, force quit the app, restore connectivity, relaunch → verify the change reaches the server.

### Implementation for User Story 3

- [x] T007 [US3] Extend `syncAllPending()` to retry pending edits and deletes in `Kiln/Services/WorkoutSyncService.swift` — after the existing bulk upload loop, add two new loops: (1) Process `pendingDeleteWorkoutIds` first — for each `localId`, call `deleteWorkoutFromServer(localId:)`, break on failure (retry next launch). (2) Then process `pendingEditWorkoutIds` — for each `localId`, skip if also in `pendingDeleteWorkoutIds` (dedup), fetch the `Workout` from the `context` by UUID, call `updateWorkout(_:)`, break on failure. This ensures deletes take precedence and edits for deleted workouts are skipped.

**Checkpoint**: Put device in airplane mode → edit a synced workout → force quit → turn off airplane mode → relaunch → verify server record updated. Repeat with delete.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and final validation

- [x] T008 Update `CLAUDE.md` with 009-workout-sync-updates changes — add PUT/DELETE endpoints to the backend endpoint list in main.py description, document new `pendingEditWorkoutIds` and `pendingDeleteWorkoutIds` UserDefaults keys in WorkoutSyncService description, note that edits trigger sync on edit view dismiss and deletes trigger sync on confirmation.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — backend can be developed and tested independently
- **US1 (Phase 2)**: Depends on Phase 1 (PUT endpoint must exist)
- **US2 (Phase 3)**: Depends on Phase 1 (DELETE endpoint must exist). Independent of US1.
- **US3 (Phase 4)**: Depends on Phase 2 AND Phase 3 (retry logic uses methods from both)
- **Polish (Phase 5)**: Depends on all phases complete

### User Story Dependencies

- **US1 (Edit Sync)**: Independent of US2 — can be implemented and tested alone
- **US2 (Delete Sync)**: Independent of US1 — can be implemented and tested alone
- **US3 (Resilience)**: Depends on both US1 and US2 — extends `syncAllPending()` to retry both

### Within Each User Story

- Sync service methods before view wiring (service must exist before views call it)
- T003 before T004 (US1)
- T005 before T006 (US2)

### Parallel Opportunities

- T001 and T002 are sequential (same file) but can be done as one commit
- T003 and T005 are sequential (same file) but US1 and US2 are logically independent
- T004 and T006 are parallel (different files, no dependencies on each other)

---

## Parallel Example: After Foundational Phase

```text
# US1 and US2 can proceed in parallel after Phase 1:

# Stream A (US1 - Edit Sync):
Task T003: Add pending edit tracking and updateWorkout() to WorkoutSyncService.swift
Task T004: Wire WorkoutEditView dismiss to trigger edit sync

# Stream B (US2 - Delete Sync):
Task T005: Add pending delete tracking and deleteWorkoutFromServer() to WorkoutSyncService.swift
Task T006: Wire HistoryListView delete to trigger server deletion

# Note: T003 and T005 modify the same file, so if done by one developer,
# do them sequentially. T004 and T006 are different files and can be parallel.
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Backend endpoints (T001, T002)
2. Complete Phase 2: US1 Edit Sync (T003, T004)
3. **STOP and VALIDATE**: Edit a synced workout → verify server updated
4. Deploy backend, build iOS

### Incremental Delivery

1. Phase 1 → Backend ready (testable with curl)
2. + US1 → Edits sync to server (MVP!)
3. + US2 → Deletes sync to server
4. + US3 → Offline resilience with retry
5. + Polish → Documentation updated

---

## Notes

- All iOS changes are in existing files — no new files created
- `WorkoutSyncService.swift` receives the most changes (T003, T005, T007) — tasks are ordered to build incrementally
- Views need `@Environment(WorkoutSessionManager.self)` to access the sync service
- `buildPayload(from:)` is already public enough to reuse for PUT — no changes needed to payload construction
- Backend reuses `WorkoutPayload` model — no changes to `models.py`
