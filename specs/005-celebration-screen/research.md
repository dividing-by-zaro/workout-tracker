# Research: Celebration Screen

## R1: Celebration Screen Insertion Point

**Decision**: Add a `celebrationData: CelebrationData?` property to `WorkoutSessionManager`. Compute stats inside `finishWorkout()` before setting `activeWorkout = nil`. Show the celebration as a `.fullScreenCover` on `ContentView` keyed off `celebrationData`.

**Rationale**: WorkoutSessionManager already owns the workout lifecycle. Storing the snapshot there means:
- The workout is properly finalized (saved, services stopped, activeWorkout nil'd)
- ContentView switches to StartWorkoutView underneath — correct state
- The fullScreenCover covers the entire screen including tab bar
- No need to delay or split the finish flow
- Simple dismiss: set `celebrationData = nil`

**Alternatives considered**:
- *Show celebration in ActiveWorkoutView before calling finishWorkout()* — rejected because the workout would remain "active" while celebration shows, blocking crash recovery and confusing the Live Activity state
- *Delay activeWorkout = nil with a timer* — rejected, fragile and race-condition-prone
- *Navigation-based approach (push celebration onto a NavigationStack)* — rejected, Workout tab doesn't use NavigationStack; adding one would change the architecture

## R2: Stats Computation

**Decision**: Create a `CelebrationData` struct that snapshots all stats. Compute it from the Workout model graph right before finishWorkout clears state. For workout count, run a SwiftData fetch counting completed workouts.

**Rationale**: All needed data already exists in the model graph:
- `Workout.totalVolume` (computed property) — total weight × reps
- `WorkoutSet.reps`, `.weight`, `.distance`, `.seconds`, `.isCompleted`
- `Exercise.resolvedEquipmentType.equipmentCategory` — determines stat relevance
- `Workout.formattedDuration` / `durationSeconds`

No new model fields needed. The CelebrationData struct is a plain value type, not persisted.

**Alternatives considered**:
- *Persist celebration data to SwiftData* — rejected, this is ephemeral display-only data; no need to store it
- *Compute stats lazily in the view* — rejected, the Workout model graph may not be accessible after finishWorkout since we nil out the reference

## R3: Adaptive Stats Display

**Decision**: Use EquipmentType's `equipmentCategory` to determine which stat categories are present in the workout. Show only stats where the corresponding category has non-zero totals. Duration and workout count always display.

**Rationale**: The five equipment categories map cleanly to display groups:
- `weightReps` → show Total Weight, Sets, Reps
- `repsOnly` → show Sets, Reps
- `duration` → show Sets (duration is always shown)
- `distance` → show Distance, Sets
- `weightDistance` → show Total Weight, Distance, Sets

At computation time, iterate exercises and accumulate which categories are present. Then filter the stat cards accordingly.

## R4: Animation Approach

**Decision**: Use a staggered spring entrance animation with scale + opacity. Stats appear one-by-one with slight delays. Add a simple confetti burst using SwiftUI Canvas or pre-built particle shapes. No third-party libraries.

**Rationale**: Constitution principle V says "Animations MUST be purposeful and subtle — never gratuitous." A tasteful spring-in with staggered stats strikes the right balance between celebration and restraint. The confetti burst is the one "wow" moment, but it's brief and doesn't loop.

Existing animation patterns in the codebase use:
- `.spring(response: 0.35, dampingFraction: 0.75)` for state transitions
- `.scale.combined(with: .opacity)` for insertions
- `withAnimation(.spring(...))` for imperative triggers

The celebration screen will follow these same patterns.

**Alternatives considered**:
- *Lottie animation* — rejected, adds a third-party dependency for a single screen
- *SpriteKit particle emitter* — rejected, overkill; SwiftUI Canvas is sufficient
- *No animation at all* — rejected, the whole point is celebration and reward

## R5: Personal Records (P3)

**Decision**: Defer to P3 scope. When implemented, compare each exercise's best completed set (weight × reps) against all historical WorkoutSets for the same exercise. Requires a SwiftData fetch per exercise.

**Rationale**: This is a nice-to-have that requires querying historical data for each exercise in the workout. The core celebration screen delivers value without it. The data model supports it without changes — just needs a fetch query at computation time.

## R6: Ordinal Formatting

**Decision**: Use a simple Swift extension on `Int` for ordinal suffixes ("1st", "2nd", "3rd", "4th", ... "11th", "12th", "13th", "21st", etc.).

**Rationale**: Standard English ordinal rules. No localization needed (single-user app, English only). The count is derived from `count + 1` of completed workouts at finish time (the current workout is being marked complete in the same operation).
