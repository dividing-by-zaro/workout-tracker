# Data Model: Workout MVP

**Branch**: `001-workout-mvp` | **Date**: 2026-02-22

## Entities

### Exercise

A named movement that can be performed in workouts.

| Field          | Type     | Constraints                       |
|----------------|----------|-----------------------------------|
| id             | UUID     | Primary key, auto-generated       |
| name           | String   | Required, unique                  |
| exerciseType   | Enum     | strength / cardio / bodyweight    |
| defaultRestSeconds | Int  | Default: 90                       |

**Notes**:
- Exercise names from Strong CSV are used as-is (e.g., "Lat Pulldown (Cable)").
- `exerciseType` is inferred during CSV import: if distance > 0 and
  seconds > 0 → cardio; if weight > 0 → strength; otherwise → bodyweight.
- `defaultRestSeconds` can be customized per exercise in template editing.

---

### WorkoutTemplate

A named collection of exercises used as a starting point for workouts.

| Field          | Type                | Constraints                 |
|----------------|---------------------|-----------------------------|
| id             | UUID                | Primary key, auto-generated |
| name           | String              | Required                    |
| createdAt      | Date                | Auto-set on creation        |
| lastUsedAt     | Date?               | Updated when workout starts |
| exercises      | [TemplateExercise]  | Ordered, cascade delete     |

---

### TemplateExercise

An exercise within a template, with default set count.

| Field          | Type         | Constraints                    |
|----------------|--------------|--------------------------------|
| id             | UUID         | Primary key, auto-generated    |
| order          | Int          | Position within template       |
| defaultSets    | Int          | Default: 3                     |
| exercise       | Exercise     | Required reference              |
| template       | WorkoutTemplate | Inverse of exercises        |

---

### Workout

A completed or in-progress training session.

| Field          | Type                | Constraints                    |
|----------------|---------------------|--------------------------------|
| id             | UUID                | Primary key, auto-generated    |
| name           | String              | From template name or custom   |
| startedAt      | Date                | Required, set when started     |
| completedAt    | Date?               | Null while in progress         |
| durationSeconds| Int?                | Computed on completion          |
| isInProgress   | Bool                | Default: true                  |
| templateId     | UUID?               | Reference to source template   |
| exercises      | [WorkoutExercise]   | Ordered, cascade delete        |

**State transitions**:
- Created → `isInProgress = true`, `completedAt = nil`
- Finished → `isInProgress = false`, `completedAt = Date.now`,
  `durationSeconds` computed from `startedAt` to `completedAt`
- Discarded → entity deleted (with cascade to exercises and sets)

**Invariant**: At most ONE workout can have `isInProgress = true` at any
time.

---

### WorkoutExercise

An exercise performed within a specific workout.

| Field          | Type         | Constraints                    |
|----------------|--------------|--------------------------------|
| id             | UUID         | Primary key, auto-generated    |
| order          | Int          | Position within workout        |
| exercise       | Exercise     | Required reference              |
| workout        | Workout      | Inverse of exercises           |
| sets           | [WorkoutSet] | Ordered, cascade delete        |

---

### WorkoutSet

A single set within a workout exercise.

| Field          | Type         | Constraints                    |
|----------------|--------------|--------------------------------|
| id             | UUID         | Primary key, auto-generated    |
| order          | Int          | Position within exercise       |
| weight         | Double?      | In lbs. Null for bodyweight    |
| reps           | Int?         | Null for cardio-only           |
| distance       | Double?      | In miles. Null for strength    |
| seconds        | Double?      | Duration. Null for strength    |
| rpe            | Double?      | Rate of perceived exertion     |
| isCompleted    | Bool         | Default: false                 |
| completedAt    | Date?        | Timestamp of completion        |
| workoutExercise| WorkoutExercise | Inverse of sets             |

**Notes**:
- For strength exercises: `weight` and `reps` are populated.
- For cardio exercises: `distance` and `seconds` are populated.
- For bodyweight exercises: `reps` is populated, `weight` is null.
- `completedAt` is set when the user taps the completion button. This
  timestamp is used to derive the most recent set data for pre-fill.

## Relationships

```text
Exercise (1) ←──── (many) TemplateExercise (many) ────→ (1) WorkoutTemplate
Exercise (1) ←──── (many) WorkoutExercise  (many) ────→ (1) Workout
                           WorkoutExercise  (1)   ────→ (many) WorkoutSet
```

- Deleting a `WorkoutTemplate` cascades to its `TemplateExercise` entries
  but does NOT delete the `Exercise` entities themselves.
- Deleting a `Workout` cascades to `WorkoutExercise` → `WorkoutSet`.
- Deleting an `Exercise` is blocked if it is referenced by any
  `WorkoutExercise` or `TemplateExercise` (prevent orphan references).

## Pre-Fill Query

To pre-fill set data for a given exercise:

1. Find the most recent `Workout` (by `completedAt` or `startedAt`) that
   contains a `WorkoutExercise` referencing this `Exercise`.
2. From that `WorkoutExercise`, retrieve all `WorkoutSet` entries ordered
   by `order`.
3. For each set position N in the current workout, use set N from the
   previous workout (if it exists). If the current workout has more sets
   than the previous, the extra sets are pre-filled with the last
   available set's data.

## CSV Import Mapping

| CSV Column     | Maps To                          |
|----------------|----------------------------------|
| Date           | Workout.startedAt                |
| Workout Name   | Workout.name                     |
| Duration       | Workout.durationSeconds (parsed) |
| Exercise Name  | Exercise.name → WorkoutExercise  |
| Set Order      | WorkoutSet.order                 |
| Weight         | WorkoutSet.weight                |
| Reps           | WorkoutSet.reps                  |
| Distance       | WorkoutSet.distance              |
| Seconds        | WorkoutSet.seconds               |
| RPE            | WorkoutSet.rpe                   |

- Rows are grouped by (Date + Workout Name) into Workout entities.
- Within a workout, rows are grouped by Exercise Name into
  WorkoutExercise entities.
- All imported workouts have `isInProgress = false` and `completedAt`
  derived from `startedAt + durationSeconds`.
