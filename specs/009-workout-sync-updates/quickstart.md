# Quickstart: Workout Sync Updates

**Feature**: 009-workout-sync-updates
**Date**: 2026-03-08

## What This Feature Does

Currently, workouts sync from the iOS app to the server as a one-time upload when completed. If a user later edits or deletes a workout in the history view, the server backup becomes stale. This feature adds bidirectional update/delete sync so the server always matches the device.

## Files to Modify

### Backend (timer-backend/)

| File | Change |
|------|--------|
| `main.py` | Add `PUT /api/workouts/{local_id}` and `DELETE /api/workouts/{local_id}` endpoints |
| `models.py` | No changes needed (reuses existing `WorkoutPayload`) |
| `db.py` | No changes needed |

### iOS Client (Kiln/)

| File | Change |
|------|--------|
| `Services/WorkoutSyncService.swift` | Add `updateWorkout()`, `deleteWorkout()`, pending tracking, bulk retry for edits/deletes |
| `Views/History/WorkoutEditView.swift` | On dismiss, call sync service to mark edited workout as pending edit |
| `Views/History/HistoryListView.swift` | On delete, call sync service to handle server deletion |

## Implementation Order

1. **Backend endpoints first** — Add PUT and DELETE to `main.py`. Can be tested independently with curl.
2. **Sync service updates** — Add update/delete methods and pending tracking to `WorkoutSyncService`.
3. **Wire up views** — Connect WorkoutEditView dismiss and HistoryListView delete to the sync service.
4. **Bulk retry** — Extend `syncAllPending()` to process pending edits and deletes on app launch.

## Testing

- Edit a synced workout name → verify server record updated (check MongoDB or call GET /api/workouts/status)
- Delete a synced workout → verify server count decreases
- Edit while offline → force quit → relaunch → verify edit syncs
- Delete while offline → relaunch → verify server record removed
- Edit then delete before sync → verify only delete is sent
