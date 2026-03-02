# Data Model: Celebration Screen

## New Types

### CelebrationData (Value Type — not persisted)

Ephemeral snapshot of workout stats, created at completion time and held in memory until the celebration screen is dismissed.

| Field | Type | Description |
|-------|------|-------------|
| workoutName | String | Name of the completed workout |
| duration | String | Formatted duration (e.g., "1h 23m") |
| durationSeconds | Int | Raw duration in seconds |
| totalVolume | Double | Sum of (weight × reps) across all completed sets |
| totalSets | Int | Count of completed sets |
| totalReps | Int | Sum of reps across all completed sets |
| totalDistance | Double | Sum of distance across all completed sets (miles) |
| workoutCount | Int | Ordinal position — total completed workouts including this one |
| hasWeightStats | Bool | True if any exercise uses weightReps or weightDistance category |
| hasRepsStats | Bool | True if any exercise uses weightReps or repsOnly category |
| hasDistanceStats | Bool | True if any exercise uses distance or weightDistance category |
| personalRecords | [PersonalRecord] | P3: list of new records set (empty array for P1/P2) |

### PersonalRecord (Value Type — P3 scope)

| Field | Type | Description |
|-------|------|-------------|
| exerciseName | String | Display name of the exercise |
| newBest | String | Formatted new best (e.g., "135 lbs × 10") |
| previousBest | String? | Formatted previous best, nil if first time |

## Existing Types (no changes needed)

### Workout (SwiftData @Model)

Already has all needed computed properties:
- `totalVolume: Double` — sum of weight × reps across all sets
- `formattedDuration: String` — human-readable duration
- `durationSeconds: Int?` — set at completion time
- `exercises: [WorkoutExercise]` — relationship to exercises

### WorkoutSet (SwiftData @Model)

Already has all needed fields:
- `weight: Double?`, `reps: Int?`, `distance: Double?`, `seconds: Double?`
- `isCompleted: Bool` — filter for completed sets only

### EquipmentType (enum)

Already has `equipmentCategory: String` with 5 categories that map to stat display logic.

## Relationships

```
WorkoutSessionManager
  └── celebrationData: CelebrationData?  (NEW — computed at finish time, nil'd on dismiss)

CelebrationData is computed FROM:
  Workout → exercises → [WorkoutExercise] → sets → [WorkoutSet]
                         └── exercise → Exercise → resolvedEquipmentType → equipmentCategory
```

## State Transitions

```
Active Workout → User taps "Finish"
  → Compute CelebrationData from Workout model graph
  → finishWorkout() saves, stops services, nils activeWorkout
  → sessionManager.celebrationData is set (non-nil)
  → ContentView presents .fullScreenCover(CelebrationView)
  → User taps "Done"
  → sessionManager.celebrationData = nil
  → fullScreenCover dismisses
  → StartWorkoutView visible underneath
```
