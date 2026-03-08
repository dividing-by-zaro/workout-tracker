# Quickstart: Workout History Sync

**Feature**: 008-workout-history-sync

## What's Being Built

Two-part sync system: a FastAPI backend extension that stores workout history in MongoDB, and an iOS service that uploads workouts automatically.

## Files to Create

### Backend (timer-backend/)
- `models.py` — Pydantic models for workout sync request/response
- New endpoints in `main.py` — `POST /api/workouts` and `GET /api/workouts/status`
- Index setup in `db.py` — new indexes for `exercises` and `workouts` collections

### iOS (Kiln/Services/)
- `WorkoutSyncService.swift` — `@MainActor @Observable` service that handles uploading workouts and tracking sync state
- Updates to `WorkoutSessionManager.swift` — trigger sync after `finishWorkout()`
- Updates to `ProfileView.swift` — display sync status indicator
- Updates to `KilnApp.swift` — inject sync service, trigger initial sync on launch

## Key Integration Points

1. **After workout completion**: `WorkoutSessionManager.finishWorkout()` → calls `WorkoutSyncService.syncWorkout(workout)`
2. **On app launch**: `KilnApp` `.task` modifier → calls `WorkoutSyncService.syncAllPending()` after auth check succeeds
3. **Profile display**: `ProfileView` reads `WorkoutSyncService.syncedCount` and `pendingCount`

## How to Test

### Backend
```bash
cd timer-backend
uv run uvicorn main:app --reload

# Upload a workout
curl -X POST http://localhost:8000/api/workouts \
  -H "Authorization: Bearer kiln_<your_key>" \
  -H "Content-Type: application/json" \
  -d '{"local_id":"test-uuid","name":"Test","started_at":"2025-01-01T00:00:00Z","completed_at":"2025-01-01T01:00:00Z","exercises":[]}'

# Check sync status
curl http://localhost:8000/api/workouts/status \
  -H "Authorization: Bearer kiln_<your_key>"
```

### iOS
1. Run `xcodegen generate`
2. Build in Xcode
3. Log in with API key
4. Complete a workout → check MongoDB for the uploaded document
5. Check Profile screen for sync status
