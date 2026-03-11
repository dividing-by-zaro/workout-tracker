# Data Model: Exercise History Browser

**Feature**: 010-exercise-history
**Date**: 2026-03-10

## Existing Entities (No Changes)

This feature introduces no new data models. It reads from existing SwiftData entities.

### Exercise (read-only)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| name | String | Unique, used for display and search |
| exerciseType | ExerciseType | .strength, .cardio, .bodyweight |
| equipmentType | EquipmentType? | Optional, resolved via `resolvedEquipmentType` |
| bodyPart | BodyPart? | Optional, resolved via `resolvedBodyPart` |

### Workout (read-only, filtered)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| startedAt | Date | Used for sorting history (most recent first) |
| completedAt | Date? | Non-nil for finished workouts |
| isInProgress | Bool | Filter: only show `false` |
| durationSeconds | Int? | Display in history cards |
| exercises | [WorkoutExercise] | Traverse to find matching exercise |

### WorkoutExercise (join entity)
| Field | Type | Notes |
|-------|------|-------|
| exercise | Exercise? | Filter by target exercise |
| workout | Workout? | Navigate to parent workout for date/metadata |
| sets | [WorkoutSet] | Display set details |
| order | Int | Original exercise order in workout |

### WorkoutSet (read-only, filtered)
| Field | Type | Notes |
|-------|------|-------|
| weight | Double? | Display based on equipment type |
| reps | Int? | Display based on equipment type |
| distance | Double? | Display based on equipment type |
| seconds | Double? | Display based on equipment type |
| rpe | Double? | Optional display |
| isCompleted | Bool | Filter: only show `true` |
| order | Int | Set number display |

## Query Patterns

### Exercise List (Exercises Tab)
```
@Query(sort: \Exercise.name) var exercises: [Exercise]
```
Sorted alphabetically. Searchable by name (case-insensitive filter).

### Exercise History (Detail View)
```
Given an Exercise, find all WorkoutExercises where:
  - workoutExercise.exercise == targetExercise
  - workoutExercise.workout?.isInProgress == false

Sort by: workoutExercise.workout?.startedAt descending

For each WorkoutExercise, display:
  - Parent workout date (workout.startedAt)
  - Completed sets only (set.isCompleted == true), sorted by set.order
```

## Relationships Diagram

```
Exercise (1) ←── WorkoutExercise (many) ──→ Workout (1)
                       │
                       ↓
                  WorkoutSet (many)
```

The exercise detail view traverses: Exercise → [WorkoutExercise] → Workout (for date) + [WorkoutSet] (for details).
