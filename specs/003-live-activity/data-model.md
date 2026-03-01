# Data Model: Live Activity Lock Screen Workout

**Feature**: 003-live-activity
**Date**: 2026-03-01

## New Entities

### WorkoutActivityAttributes (ActivityKit)

Static data set once when the Live Activity is started. Immutable for the activity's lifetime.

| Field | Type | Description |
|-------|------|-------------|
| workoutName | String | Workout display name (e.g., "Legs A") |
| workoutStartedAt | Date | Wall-clock start time for elapsed counter |

### WorkoutActivityAttributes.ContentState (ActivityKit)

Dynamic data updated via `Activity.update()` on every state change.

| Field | Type | Description |
|-------|------|-------------|
| exerciseName | String | Current exercise display name |
| setNumber | Int | Current set's 1-based index within its exercise |
| totalSetsInExercise | Int | Total sets for the current exercise |
| previousSetLabel | String | Formatted previous set data (e.g., "55 lbs x 8", "— " if none) |
| weight | Double? | Current set weight value (nil if equipment doesn't track weight) |
| reps | Int? | Current set reps value (nil if equipment doesn't track reps) |
| duration | Double? | Current set duration in seconds (nil if not duration-based) |
| distance | Double? | Current set distance value (nil if not distance-based) |
| equipmentCategory | String | One of: "weightReps", "repsOnly", "duration", "distance", "weightDistance" — determines which input fields and +/- buttons to show |
| isRestTimerActive | Bool | Whether the rest countdown is currently running |
| restTimerEndDate | Date | Absolute end time for rest timer countdown (used by `Text(timerInterval:)`) |
| restTotalSeconds | Int | Total rest duration (for progress calculation) |
| isWorkoutComplete | Bool | True when all sets across all exercises are completed |
| exerciseIndex | Int | 1-based index of current exercise in workout order |
| totalExercises | Int | Total number of exercises in the workout |

**Size estimate**: ~250 bytes typical, well within 4 KB ContentState limit.

### Equipment Category Mapping

Maps from the existing `EquipmentType` enum (9 cases) to 5 display categories for the Live Activity:

| EquipmentType | Category | Fields Shown | +/- Targets |
|---------------|----------|-------------|-------------|
| barbell, dumbbell, kettlebell, machineOther, weightedBodyweight | weightReps | weight + reps | weight (±1 lb), reps (±1) |
| repsOnly | repsOnly | reps only | reps (±1) |
| duration | duration | seconds only | seconds (±5) |
| distance | distance | distance only | distance (±0.1) |
| weightedDistance | weightDistance | weight + distance | weight (±1 lb), distance (±0.1) |

## Modified Entities

### WorkoutSessionManager (existing service)

New state and methods added:

| Addition | Type | Description |
|----------|------|-------------|
| currentActivity | Activity\<WorkoutActivityAttributes\>? | Reference to the active Live Activity instance |
| currentSetProgression | (exerciseIndex: Int, setIndex: Int)? | Cached position of the current incomplete set |

New methods:

| Method | Trigger | Effect |
|--------|---------|--------|
| startLiveActivity() | Called from startWorkout / startEmptyWorkout | Creates Activity with initial ContentState |
| updateLiveActivity() | Called after any state change (set complete, weight/reps change, timer start/stop) | Calls Activity.update() with fresh ContentState |
| endLiveActivity() | Called from finishWorkout / discardWorkout / reset | Calls Activity.end() with .immediate dismissal |
| findCurrentSet() -> (WorkoutExercise, WorkoutSet)? | Called by updateLiveActivity | Scans exercises in order for first incomplete set |
| completeCurrentSetFromIntent() | Called by CompleteSetIntent.perform() | Completes the current set, starts rest timer, updates live activity |
| adjustWeightFromIntent(delta:) | Called by AdjustWeightIntent.perform() | Adjusts current set's weight, updates live activity |
| adjustRepsFromIntent(delta:) | Called by AdjustRepsIntent.perform() | Adjusts current set's reps, updates live activity |
| skipRestTimerFromIntent() | Called by SkipRestIntent.perform() | Stops rest timer, advances to next set, updates live activity |

### RestTimerService (existing service)

New callback:

| Addition | Type | Description |
|----------|------|-------------|
| onTimerExpired | (() -> Void)? | Callback invoked when timer reaches zero, allowing WorkoutSessionManager to update the Live Activity and play the alert sound via AlertConfiguration |

## App Intents

### CompleteSetIntent

| Property | Value |
|----------|-------|
| Protocol | LiveActivityIntent |
| isDiscoverable | false |
| openAppWhenRun | false |
| Action | Calls WorkoutSessionManager.completeCurrentSetFromIntent() |

### AdjustWeightIntent

| Property | Value |
|----------|-------|
| Protocol | LiveActivityIntent |
| isDiscoverable | false |
| openAppWhenRun | false |
| Parameter | delta: Int (±1 for weight, ±5 for duration, ±0.1 for distance) |
| Action | Calls WorkoutSessionManager.adjustWeightFromIntent(delta:) |

### AdjustRepsIntent

| Property | Value |
|----------|-------|
| Protocol | LiveActivityIntent |
| isDiscoverable | false |
| openAppWhenRun | false |
| Parameter | delta: Int (±1) |
| Action | Calls WorkoutSessionManager.adjustRepsFromIntent(delta:) |

### SkipRestIntent

| Property | Value |
|----------|-------|
| Protocol | LiveActivityIntent |
| isDiscoverable | false |
| openAppWhenRun | false |
| Action | Calls WorkoutSessionManager.skipRestTimerFromIntent() |

## State Transitions

```
[No Workout]
    → startWorkout()
    → [Set View: showing first incomplete set]

[Set View]
    → user taps Complete
    → completeSet() + startRestTimer()
    → [Timer View: countdown running]

[Timer View]
    → timer expires (or user skips)
    → findCurrentSet()
    → [Set View: next incomplete set] OR [Complete View: all done]

[Set View]
    → user taps +/- weight or reps
    → adjustWeight/Reps()
    → [Set View: updated values]

[Complete View]
    → user taps Live Activity
    → app opens via widgetURL
    → user finishes workout in app

[Any State]
    → finishWorkout() or discardWorkout()
    → endLiveActivity()
    → [No Workout]
```

## File Organization

Files shared between both targets (main app + widget extension):
- `WorkoutActivityAttributes.swift` — ActivityAttributes + ContentState
- `WorkoutLiveActivityIntents.swift` — Intent struct declarations (no perform bodies)

Files in main app target only:
- `WorkoutLiveActivityIntents+App.swift` — Intent perform() implementations
- `LiveActivityService.swift` — Manages Activity lifecycle (start/update/end)

Files in widget extension target only:
- `KilnWidgetBundle.swift` — @main WidgetBundle entry point
- `WorkoutLiveActivityView.swift` — Lock screen SwiftUI views (set view, timer view, complete view)
- `WorkoutLiveActivityIntents+Widget.swift` — Intent perform() stubs
- `Assets.xcassets` — Subset of design tokens (colors, brick icon) for widget rendering
