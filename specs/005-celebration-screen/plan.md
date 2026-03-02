# Implementation Plan: Celebration Screen

**Branch**: `005-celebration-screen` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-celebration-screen/spec.md`

## Summary

After a user taps "Finish" (or "Finish & Update Template"), a full-screen celebration view appears showing an encouraging animation, the user's ordinal workout count ("Your 47th workout!"), and adaptive stats (duration, weight lifted, sets, reps, distance) filtered by exercise type. The celebration view is presented as a `.fullScreenCover` on ContentView, driven by a `CelebrationData` snapshot computed on `WorkoutSessionManager` immediately before the workout is finalized.

## Technical Context

**Language/Version**: Swift 5.9+ / SwiftUI
**Primary Dependencies**: SwiftUI (views, animations), SwiftData (workout count query)
**Storage**: SwiftData (existing — no schema changes)
**Testing**: Manual verification on iPhone 13 device/simulator
**Target Platform**: iOS 17+ (iPhone 13)
**Project Type**: Mobile app (iOS)
**Performance Goals**: Celebration screen appears within 1 second of tapping finish
**Constraints**: No third-party animation libraries; animations must be purposeful and subtle per constitution
**Scale/Scope**: 2 new files, 2 modified files; single new screen

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Workout is saved to SwiftData before celebration displays. `finishWorkout()` calls `context.save()` before any UI transition. No data flow changes. |
| II. Minimal Friction | PASS | Celebration adds one screen between finish and template grid, dismissed with a single tap. This is additive UX, not friction — the user chose to finish. |
| III. Timer Reliability | PASS | No timer changes. Rest timer is stopped in `finishWorkout()` before celebration shows. |
| IV. Live Activity First | PASS | Live Activity is ended in `finishWorkout()` before celebration shows. No Live Activity changes. |
| V. Beautiful & Joyful Design | PASS | This feature directly fulfills "visually delightful interface." Animations are purposeful (celebration reward) and subtle (spring transitions, brief confetti). Uses DesignSystem tokens throughout. |
| VI. Single-User Simplicity | PASS | No multi-user concerns. Workout count is a simple total of all completed workouts. |
| VII. Data Portability | N/A | No data schema changes. |

**Pre-design gate**: PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/005-celebration-screen/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research decisions
├── data-model.md        # Phase 1 data model
├── quickstart.md        # Phase 1 quickstart guide
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Kiln/
├── Models/
│   └── CelebrationData.swift    # NEW — value type struct with workout summary stats
├── Views/
│   └── Workout/
│       └── CelebrationView.swift # NEW — full-screen celebration SwiftUI view
├── Services/
│   └── WorkoutSessionManager.swift  # MODIFIED — add celebrationData property + computation
└── Views/
    └── ContentView.swift            # MODIFIED — add .fullScreenCover presentation
```

**Structure Decision**: All new code fits within the existing Kiln/ directory structure. Two new files in their natural locations (model in Models/, view in Views/Workout/). Two existing files modified with minimal changes. No new directories needed.

## Design Decisions

### D1: Celebration Data Lifecycle

The `CelebrationData` struct is computed from the Workout model graph inside a new method on `WorkoutSessionManager`. The method is called at the top of `finishWorkout()` and `finishAndUpdateTemplate()`, before `activeWorkout` is set to nil. The snapshot is stored in `sessionManager.celebrationData`. ContentView observes this property and presents a `.fullScreenCover` when non-nil. Dismissing the celebration sets it back to nil.

**Flow**:
1. User taps "Finish" → ActiveWorkoutView calls `sessionManager.finishWorkout(context:)`
2. `finishWorkout()` computes `CelebrationData` from `activeWorkout` model graph
3. `finishWorkout()` saves workout, stops services, nils `activeWorkout`
4. `sessionManager.celebrationData` is now set → triggers `.fullScreenCover`
5. Underneath, ContentView switches to StartWorkoutView (correct)
6. CelebrationView displays with animation
7. User taps "Done" → `sessionManager.celebrationData = nil` → cover dismisses

### D2: Stats Computation

Stats are computed by iterating all completed sets across all exercises:

- **Total volume**: Already exists as `Workout.totalVolume`
- **Total sets**: `exercises.flatMap(\.sets).filter(\.isCompleted).count`
- **Total reps**: `exercises.flatMap(\.sets).filter(\.isCompleted).compactMap(\.reps).reduce(0, +)`
- **Total distance**: `exercises.flatMap(\.sets).filter(\.isCompleted).compactMap(\.distance).reduce(0, +)`
- **Workout count**: SwiftData `FetchDescriptor<Workout>` counting `isInProgress == false` (after save, so it includes the just-finished workout)
- **Category flags**: Iterate exercises, check `exercise.resolvedEquipmentType.equipmentCategory`, set boolean flags for weight/reps/distance presence

### D3: Adaptive Display

Stats shown on the celebration screen are filtered by category flags:

| Always shown | Shown when present |
|---|---|
| Duration | Total Weight Lifted (hasWeightStats) |
| Workout Count | Total Reps (hasRepsStats) |
| | Total Sets (always if any completed sets) |
| | Total Distance (hasDistanceStats) |

### D4: Visual Design

The celebration screen follows the fire/warm theme:
- Full-screen warm cream background with grain texture (`.grainedBackground()`)
- Large ordinal text ("Your 47th workout!") in `DesignSystem.Colors.primary` (fire red)
- Encouraging subtitle (e.g., "Great work!" or "Keep the fire burning!")
- Stats displayed in rounded cards with `CardGrainOverlay`, using warm tones
- Each stat: icon + value + label (e.g., flame icon + "12,450" + "lbs lifted")
- "Done" button in primary style (fire red capsule)

### D5: Animation

- **Screen entrance**: `.fullScreenCover` with default iOS presentation animation
- **Content entrance**: Title and stats scale from 0.8 + fade in with staggered spring delays
- **Confetti burst**: Brief particle animation using SwiftUI Canvas — small ember-colored shapes (reds, oranges, golds) that burst upward and fade. Plays once on appear, lasts ~2 seconds.
- **Done button**: Fades in after stats animation completes

### D6: Ordinal Formatting

Swift `Int` extension with `ordinalString` computed property:
- Special cases for 11th, 12th, 13th (not 11st, 12nd, 13th)
- Standard suffixes: 1→st, 2→nd, 3→rd, all others→th
- Applied to workout count: `"\(count.ordinalString) workout"`

## Post-Design Constitution Re-Check

| Principle | Status | Change from pre-design |
|-----------|--------|----------------------|
| I. Zero Data Loss | PASS | No change — `finishWorkout()` saves before computing celebration data |
| II. Minimal Friction | PASS | No change — single tap dismiss |
| V. Beautiful & Joyful Design | PASS | Confirmed: uses DesignSystem tokens, grain texture, warm theme; animations are brief and purposeful |

**Post-design gate**: PASS — no new violations.

## Complexity Tracking

No constitution violations to justify. The implementation adds:
- 1 value type struct (CelebrationData)
- 1 new view (CelebrationView)
- ~20 lines added to WorkoutSessionManager (computation + property)
- ~5 lines added to ContentView (fullScreenCover binding)
