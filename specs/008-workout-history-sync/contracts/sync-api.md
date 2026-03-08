# API Contract: Workout History Sync

**Feature**: 008-workout-history-sync
**Base URL**: `{TIMER_BACKEND_URL}` (same backend as timer and auth endpoints)

## Authentication

All endpoints require:
```
Authorization: Bearer kiln_<random_token>
```

The authenticated user is resolved from the API key via the existing auth middleware. The user's `_id` is used as `user_id` for all sync operations.

---

## Endpoints

### POST /api/workouts

Upload a single completed workout. Idempotent — if a workout with the same `local_id` already exists for this user, it is silently ignored (no error, no update).

**Request**:
```json
{
  "local_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
  "name": "Legs",
  "started_at": "2025-07-26T18:14:37Z",
  "completed_at": "2025-07-26T18:53:37Z",
  "duration_seconds": 2340,
  "exercises": [
    {
      "order": 0,
      "exercise_name": "Squat (Dumbbell)",
      "exercise_type": "strength",
      "body_part": "legs",
      "equipment_type": "dumbbell",
      "sets": [
        {
          "order": 0,
          "weight": 20.0,
          "reps": 12,
          "distance": null,
          "seconds": null,
          "rpe": null,
          "completed_at": "2025-07-26T18:20:00Z"
        },
        {
          "order": 1,
          "weight": 20.0,
          "reps": 12,
          "distance": null,
          "seconds": null,
          "rpe": null,
          "completed_at": "2025-07-26T18:23:00Z"
        }
      ]
    },
    {
      "order": 1,
      "exercise_name": "Leg Extension (Machine)",
      "exercise_type": "strength",
      "body_part": "legs",
      "equipment_type": "machineOther",
      "sets": [
        {
          "order": 0,
          "weight": 30.0,
          "reps": 8,
          "distance": null,
          "seconds": null,
          "rpe": null,
          "completed_at": "2025-07-26T18:30:00Z"
        }
      ]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| local_id | string | yes | SwiftData UUID (deduplication key) |
| name | string | yes | Workout name |
| started_at | string (ISO 8601) | yes | Workout start time |
| completed_at | string (ISO 8601) | yes | Workout completion time |
| duration_seconds | integer | no | Total workout duration |
| exercises | array | yes | Ordered list of exercises with sets |
| exercises[].order | integer | yes | Position in workout (0-based) |
| exercises[].exercise_name | string | yes | Exercise name |
| exercises[].exercise_type | string | yes | "strength", "cardio", or "bodyweight" |
| exercises[].body_part | string | no | Body part enum value |
| exercises[].equipment_type | string | no | Equipment type enum value |
| exercises[].sets | array | yes | Ordered list of sets |
| exercises[].sets[].order | integer | yes | Position in exercise (0-based) |
| exercises[].sets[].weight | float | no | Weight in lbs |
| exercises[].sets[].reps | integer | no | Repetitions |
| exercises[].sets[].distance | float | no | Distance |
| exercises[].sets[].seconds | float | no | Duration |
| exercises[].sets[].rpe | float | no | Rate of perceived exertion |
| exercises[].sets[].completed_at | string (ISO 8601) | no | When set was completed |

**Response (201 Created)** — new workout saved:
```json
{
  "status": "created",
  "local_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
}
```

**Response (200 OK)** — workout already exists (idempotent):
```json
{
  "status": "exists",
  "local_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
}
```

**Response (401 Unauthorized)**:
```json
{
  "error": "Invalid API key"
}
```

**Response (422 Unprocessable Entity)**:
```json
{
  "detail": [
    {
      "loc": ["body", "local_id"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

### Behavior

- On successful save: inserts workout document into `workouts` collection with the authenticated user's `_id` as `user_id`.
- Upserts each referenced exercise into the `exercises` collection (matched by `user_id` + `exercise_name`). Updates `body_part`, `equipment_type`, `exercise_type`, and `updated_at` if the exercise already exists.
- Deduplication: checks `(user_id, local_id)` unique index. If a document already exists, returns 200 with `"status": "exists"` without modifying the existing record.

---

### GET /api/workouts/status

Get sync status for the authenticated user. Returns the count of synced workouts.

**Request**:
```
GET /api/workouts/status
Authorization: Bearer kiln_abc123...
```

**Response (200)**:
```json
{
  "synced_count": 47
}
```

**Notes**:
- Used by the iOS app to display sync status on the profile screen.
- The app compares this count against the local completed workout count to determine if everything is synced.

---

## Error Handling

All endpoints follow the existing backend error patterns:
- `401` for invalid/missing API key (handled by auth middleware)
- `422` for request validation errors (handled by FastAPI/Pydantic)
- `500` for unexpected server errors

The iOS client should:
- On `401`: trigger logout (existing behavior)
- On `422`: log error but do not retry (malformed data)
- On `500` or network error: mark workout as pending and retry on next app launch
