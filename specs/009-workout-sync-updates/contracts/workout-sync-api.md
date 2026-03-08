# API Contract: Workout Sync Updates

**Feature**: 009-workout-sync-updates
**Date**: 2026-03-08
**Base URL**: `{TIMER_BACKEND_URL}`

## Authentication

All endpoints require `Authorization: Bearer {api_key}` header. Existing auth middleware scopes all operations to the authenticated user.

---

## PUT /api/workouts/{local_id}

Replace an existing workout document on the server.

### Request

**Path Parameters**:
- `local_id` (string, required): The workout's local UUID string

**Body**: Same as existing `POST /api/workouts` payload (reuses `WorkoutPayload` model)

```json
{
  "local_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Updated Workout Name",
  "started_at": "2026-03-08T10:00:00Z",
  "completed_at": "2026-03-08T11:15:00Z",
  "duration_seconds": 4500,
  "exercises": [
    {
      "order": 0,
      "exercise_name": "Bench Press",
      "exercise_type": "strength",
      "body_part": "chest",
      "equipment_type": "barbell",
      "sets": [
        {
          "order": 0,
          "weight": 135.0,
          "reps": 10,
          "completed_at": "2026-03-08T10:05:00Z"
        }
      ]
    }
  ]
}
```

### Responses

| Status | Condition | Body |
|--------|-----------|------|
| 200    | Workout found and replaced | `{"status": "updated", "local_id": "..."}` |
| 404    | No workout with this `local_id` for the authenticated user | `{"error": "Workout not found"}` |
| 422    | Validation error in payload | Standard FastAPI validation error |

### Behavior
- Replaces the entire workout document (all exercises and sets)
- Updates `synced_at` to current server time
- Upserts exercise metadata in the `exercises` collection (same as POST)
- `local_id` in path must match `local_id` in body

---

## DELETE /api/workouts/{local_id}

Remove a workout document from the server.

### Request

**Path Parameters**:
- `local_id` (string, required): The workout's local UUID string

**Body**: None

### Responses

| Status | Condition | Body |
|--------|-----------|------|
| 200    | Workout found and deleted | `{"status": "deleted", "local_id": "..."}` |
| 404    | No workout with this `local_id` for the authenticated user | `{"error": "Workout not found"}` |

### Behavior
- Hard deletes the workout document from the `workouts` collection
- Does NOT delete exercise metadata from the `exercises` collection (exercises may be referenced by other workouts)
- Scoped to authenticated user (cannot delete another user's workouts)

---

## Existing Endpoints (Unchanged)

### POST /api/workouts
No changes. Continues to create new workout documents with idempotent duplicate handling.

### GET /api/workouts/status
No changes. Returns `synced_count` which will naturally reflect updates and deletions.
