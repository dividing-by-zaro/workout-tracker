# Data Model: Workout Sync Updates

**Feature**: 009-workout-sync-updates
**Date**: 2026-03-08

## Existing Entities (No Changes)

### Workout (SwiftData)
Unchanged. The `Workout` model already contains all fields needed. No schema migration.

### Workout Document (MongoDB)
Unchanged. The workout document structure in the `workouts` collection already supports full replacement.

## New State: Sync Tracking (UserDefaults)

### Pending Edit Set
- **Key**: `pendingEditWorkoutIds`
- **Type**: `Set<String>` (workout UUID strings)
- **Purpose**: Tracks synced workouts that have been edited locally and need to be re-uploaded
- **Lifecycle**: ID added when user dismisses WorkoutEditView for a synced workout → ID removed after successful PUT to server

### Pending Delete Set
- **Key**: `pendingDeleteWorkoutIds`
- **Type**: `Set<String>` (workout UUID strings)
- **Purpose**: Tracks synced workouts that have been deleted locally and need to be removed from server
- **Lifecycle**: ID added when user confirms deletion of a synced workout → ID removed after successful DELETE from server

## State Transitions

```
                    ┌──────────────┐
                    │  Not Synced  │ (workout exists locally, not in syncedWorkoutIds)
                    └──────┬───────┘
                           │ uploadWorkout() succeeds
                           ▼
                    ┌──────────────┐
            ┌───── │    Synced     │ (in syncedWorkoutIds, not in pending sets)
            │      └──┬───────┬───┘
            │         │       │
     user edits       │       │ user deletes
            │         ▼       ▼
            │  ┌────────┐  ┌────────────┐
            │  │ Pending │  │  Pending   │
            │  │  Edit   │  │  Delete    │
            │  └────┬────┘  └─────┬──────┘
            │       │             │
            │  PUT succeeds  DELETE succeeds
            │       │             │
            │       ▼             ▼
            │  ┌────────┐  ┌────────────┐
            └─►│ Synced  │  │  Removed   │ (removed from all tracking sets)
               └────────┘  └────────────┘
```

## Deduplication Rules

1. If a workout ID is in `pendingEditWorkoutIds` and then added to `pendingDeleteWorkoutIds`: remove from `pendingEditWorkoutIds` (delete supersedes edit).
2. If a workout ID is NOT in `syncedWorkoutIds`: editing it requires no server action (the next initial sync will upload the edited version).
3. If a workout ID is NOT in `syncedWorkoutIds`: deleting it requires no server action (just remove local data).
