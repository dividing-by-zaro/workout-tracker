# Research: Workout Sync Updates

**Feature**: 009-workout-sync-updates
**Date**: 2026-03-08

## Decision 1: Update Strategy — Full Replace vs Partial Patch

**Decision**: Full document replacement via PUT endpoint.

**Rationale**: The existing `buildPayload()` already constructs the complete workout representation. Using the same payload format for updates keeps the client simple — just re-send the full workout. MongoDB's `replace_one` is a single atomic operation. Partial patches would require diffing logic on the client and a more complex PATCH handler on the server, with no meaningful performance benefit for documents this small (a workout with ~10 exercises and ~30 sets is <5KB).

**Alternatives considered**:
- PATCH with partial updates: More complex, no real benefit at this scale.
- Delete + re-insert: Fragile — if delete succeeds but insert fails, data is lost on server.

## Decision 2: Pending Operations Storage

**Decision**: Store pending edit IDs and pending delete IDs in UserDefaults (separate keys from `syncedWorkoutIds`).

**Rationale**: Consistent with the existing `syncedWorkoutIds` pattern. UserDefaults is already the persistence layer for sync state. Two new keys: `pendingEditWorkoutIds` (Set<String>) and `pendingDeleteWorkoutIds` (Set<String>). Simple, reliable, no new dependencies.

**Alternatives considered**:
- SwiftData model for pending ops: Over-engineered for a set of UUIDs. Would require schema migration.
- File-based queue: More complex, no benefit over UserDefaults for small data.

## Decision 3: When to Trigger Edit Sync

**Decision**: Mark workout as pending edit when the WorkoutEditView is dismissed (on "Done" tap), then process immediately. Also process pending edits during bulk sync on app launch.

**Rationale**: The edit view already saves to SwiftData on each field change, but we don't want to fire a network request on every keystroke. Waiting for dismiss ensures we send the final state. If the network request fails, the ID stays in the pending set and retries on next launch.

**Alternatives considered**:
- Sync on every save: Too many requests, especially during name editing.
- Sync only on app launch: Too slow — user expects near-immediate backup after editing.

## Decision 4: Backend Endpoint Design

**Decision**:
- `PUT /api/workouts/{local_id}` — replaces the workout document
- `DELETE /api/workouts/{local_id}` — removes the workout document

**Rationale**: RESTful resource-oriented design. `local_id` is already the unique identifier used by the client. The PUT endpoint reuses the existing `WorkoutPayload` model. Both endpoints are scoped to the authenticated user via the existing auth middleware.

**Alternatives considered**:
- `PATCH /api/workouts/{local_id}`: Would require a different payload model and merge logic. Unnecessary complexity.
- `POST /api/workouts/delete`: Non-RESTful. No benefit over DELETE.

## Decision 5: Deduplication of Pending Operations

**Decision**: When a workout appears in both pending edits and pending deletes, the delete takes precedence. When processing pending operations, check deletes first and skip any edit for the same ID.

**Rationale**: If the user edited then deleted, the workout no longer exists locally — sending an edit would be wasteful and potentially confusing. The delete is the authoritative final state.

## Decision 6: Profile Sync Count After Deletes

**Decision**: When a synced workout is deleted locally, remove its ID from `syncedWorkoutIds` immediately. After the server delete succeeds, the server count will also decrease. The `pendingCount` computation naturally accounts for this since `totalCompletedCount` decreases (workout is gone from SwiftData) and `syncedCount` decreases (ID removed from set).

**Rationale**: Keeps the profile sync status accurate without needing to query the server for the count.
