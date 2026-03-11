# Research: Exercise History Browser

**Feature**: 010-exercise-history
**Date**: 2026-03-10

## Decision 1: Tab Placement

**Decision**: Add the Exercises tab as tag 2, between History (becomes tag 1, unchanged) and Profile (becomes tag 3).

**Rationale**: Exercises is closely related to History (both are read-only browsing of past data) and logically groups next to it. Profile is the least-used tab and belongs at the end.

**Alternatives considered**:
- After Profile (tag 3): Hides the new feature; users expect profile at the end
- Before History (tag 1): Disrupts existing muscle memory for History tab

## Decision 2: Tab Icon

**Decision**: Use SF Symbol `"list.bullet"` for the Exercises tab. Add a new `DesignSystem.Icon.exercises` constant.

**Rationale**: The dumbbell icon is already used for the Workouts tab. `list.bullet` conveys a catalog/library concept and is visually distinct. Other options like `figure.strengthtraining.traditional` are too similar to the dumbbell.

**Alternatives considered**:
- `figure.strengthtraining.traditional`: Too similar to dumbbell, confusing next to Workouts tab
- `books.vertical`: Too abstract, not fitness-related
- `text.justify.left`: Too generic

## Decision 3: Exercise History Data Access Pattern

**Decision**: Query WorkoutExercises by matching `exercise.persistentModelID` from finished workouts (`isInProgress == false`), then group by parent workout, sorted by `workout.startedAt` descending.

**Rationale**: SwiftData `@Query` with predicates can filter by exercise relationship. Grouping by workout keeps the display consistent with how users think about their sessions. Only showing finished workouts avoids partial/abandoned workout data.

**Alternatives considered**:
- Flat list of all sets: Loses workout context (date, what else was done)
- Pre-computed aggregate table: Unnecessary complexity for a two-user app with local-only data

## Decision 4: Exercise List Content

**Decision**: Show ALL exercises in the Exercise model (both imported and user-created), regardless of whether they have workout history. The exercise detail view handles the empty-history case.

**Rationale**: This matches the spec requirement and mirrors the exercise picker behavior. Users may want to see exercises they've created but not yet used.

**Alternatives considered**:
- Only exercises with history: Would confuse users who can't find exercises they created
- Separate sections (with/without history): Over-engineering for the scope

## Decision 5: No New Models Needed

**Decision**: No new SwiftData models are required. The feature reads existing Exercise, Workout, WorkoutExercise, and WorkoutSet models.

**Rationale**: All required data already exists. Exercise detail view queries WorkoutExercise entities filtered by exercise, then traverses to their parent Workout and child WorkoutSet objects.

## Decision 6: No Server-Side Changes

**Decision**: This feature is purely client-side. No backend API changes needed.

**Rationale**: All exercise and workout data is in local SwiftData. The feature only reads existing data — no new data is created, updated, or synced.
