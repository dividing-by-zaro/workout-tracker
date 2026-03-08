# Data Model: Workout History Sync

**Feature**: 008-workout-history-sync
**Date**: 2026-03-08

## MongoDB Collections

### `exercises` Collection

Stores unique exercise definitions per user. Referenced by workout documents.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB primary key |
| `user_id` | ObjectId | yes | Reference to `users._id` |
| `name` | string | yes | Exercise name (e.g., "Goblet Squat (Kettlebell)") |
| `exercise_type` | string | yes | One of: "strength", "cardio", "bodyweight" |
| `body_part` | string | no | One of: "chest", "back", "shoulders", "arms", "legs", "core", "cardio", "fullBody", "other" |
| `equipment_type` | string | no | One of: "barbell", "dumbbell", "kettlebell", "machineOther", "weightedBodyweight", "repsOnly", "duration", "distance", "weightedDistance" |
| `created_at` | datetime | yes | When exercise was first synced |
| `updated_at` | datetime | yes | When exercise was last updated |

**Indexes**:
- `{ user_id: 1, name: 1 }` — unique compound index (one exercise definition per name per user)

---

### `workouts` Collection

Stores completed workout sessions with embedded exercises and sets.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB primary key |
| `user_id` | ObjectId | yes | Reference to `users._id` |
| `local_id` | string | yes | SwiftData UUID string (deduplication key) |
| `name` | string | yes | Workout name (e.g., "Legs", "Back and Biceps") |
| `started_at` | datetime | yes | When workout began |
| `completed_at` | datetime | yes | When workout was finished |
| `duration_seconds` | integer | no | Total workout duration |
| `exercises` | array | yes | Ordered list of exercises performed (embedded) |
| `synced_at` | datetime | yes | When this record was written to the server |

**Indexes**:
- `{ user_id: 1, local_id: 1 }` — unique compound index (prevents duplicate workouts per user)

#### Embedded: `exercises[]` (Workout Exercise)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `order` | integer | yes | Position within workout (0-based) |
| `exercise_name` | string | yes | Exercise name (matches `exercises.name`) |
| `sets` | array | yes | Ordered list of sets performed |

#### Embedded: `exercises[].sets[]` (Workout Set)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `order` | integer | yes | Position within exercise (0-based) |
| `weight` | float | no | Weight in lbs |
| `reps` | integer | no | Repetitions |
| `distance` | float | no | Distance (for cardio) |
| `seconds` | float | no | Duration (for timed exercises) |
| `rpe` | float | no | Rate of perceived exertion |
| `completed_at` | datetime | no | When set was completed |

---

## Local Sync State (UserDefaults)

| Key | Type | Description |
|-----|------|-------------|
| `syncedWorkoutIds` | `[String]` | Array of UUID strings for workouts successfully uploaded |

Stored in standard UserDefaults (not App Group — only accessed from main app process).

---

## Relationships

```
users (existing)
  └── exercises (1:many, by user_id)
  └── workouts (1:many, by user_id)
        └── exercises[] (embedded array)
              └── sets[] (embedded array)
```

- Each workout references exercises by `exercise_name` (denormalized for query simplicity)
- The `exercises` collection serves as the canonical exercise catalog per user
- Workout exercises embed the exercise name directly — no foreign key joins needed
