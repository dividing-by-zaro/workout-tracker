# Tasks: Celebration Screen

**Input**: Design documents from `/specs/005-celebration-screen/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not requested — manual verification only per quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Foundational

**Purpose**: Shared data types needed by all user stories

- [x] T001 Create `CelebrationData` struct (all fields from data-model.md), `PersonalRecord` struct, and `Int.ordinalString` computed property extension in `Kiln/Models/CelebrationData.swift`. The ordinal extension must handle 11th/12th/13th special cases. `PersonalRecord` can have an empty implementation for now (P3 scope). Include all category flag fields (`hasWeightStats`, `hasRepsStats`, `hasDistanceStats`).

**Checkpoint**: CelebrationData.swift compiles with all fields defined.

---

## Phase 2: User Story 1 — Workout Completion Celebration (Priority: P1) 🎯 MVP

**Goal**: After tapping "Finish" or "Finish & Update Template", a full-screen celebration view appears with an encouraging animation, ordinal workout count, and workout summary stats.

**Independent Test**: Complete any workout → tap Finish → celebration screen appears with correct stats, animation plays, "Done" dismisses to template grid.

### Implementation for User Story 1

- [x] T002 [P] [US1] Add `celebrationData: CelebrationData?` property and `computeCelebrationData(context:)` method to `WorkoutSessionManager` in `Kiln/Services/WorkoutSessionManager.swift`. The method must: (1) snapshot `totalVolume`, `formattedDuration`, `durationSeconds` from `activeWorkout`, (2) compute `totalSets` (completed sets count), `totalReps` (sum of reps on completed sets), `totalDistance` (sum of distance on completed sets), (3) compute `hasWeightStats`/`hasRepsStats`/`hasDistanceStats` by checking `exercise.resolvedEquipmentType.equipmentCategory` across all workout exercises, (4) query workout count via `FetchDescriptor<Workout>` filtering `isInProgress == false` (after save), (5) set `personalRecords` to empty array. Then modify `finishWorkout(context:)` to call `computeCelebrationData(context:)` BEFORE setting `activeWorkout = nil`. Also call it at the top of `finishAndUpdateTemplate(context:)` before it calls `finishWorkout(context:)`.

- [x] T003 [P] [US1] Create `CelebrationView` in `Kiln/Views/Workout/CelebrationView.swift`. Takes `CelebrationData` and a `dismiss` closure. Layout: (1) `.grainedBackground()` full screen, (2) "Your Nth workout!" headline using `data.workoutCount.ordinalString` in `DesignSystem.Colors.primary` with `DesignSystem.Typography.title`, (3) encouraging subtitle in `DesignSystem.Colors.textSecondary`, (4) stat cards in a grid/VStack showing duration, total weight (formatted with comma separator + "lbs"), total sets, total reps, total distance (formatted as "X.X mi") — for MVP show all stats where value > 0, (5) confetti/ember burst animation using SwiftUI `Canvas` with `TimelineView` — ember-colored circles (reds/oranges/golds from DesignSystem.Colors) that burst upward and fade over ~2 seconds, (6) "Done" capsule button in `DesignSystem.Colors.primary` calling dismiss closure. Use staggered spring entrance animations: title appears first, then stats with 0.1s delays each, then Done button. Each stat card uses `CardGrainOverlay` and `.cardShadow()`.

- [x] T004 [US1] Add `.fullScreenCover` to `ContentView` in `Kiln/Views/ContentView.swift`. Bind `isPresented` to a computed binding: `sessionManager.celebrationData != nil`. In the cover content, instantiate `CelebrationView(data: sessionManager.celebrationData!, onDismiss: { sessionManager.celebrationData = nil })`. Place the modifier on the `TabView`.

- [x] T005 [US1] Run `xcodegen generate` from repo root to regenerate `Kiln.xcodeproj` with the new `CelebrationData.swift` and `CelebrationView.swift` files.

**Checkpoint**: Complete a workout via "Finish" → celebration screen appears with all non-zero stats, animation plays, "Done" returns to template grid. Repeat with "Finish & Update Template" — same result. Verify on iPhone 13 simulator.

---

## Phase 3: User Story 2 — Adaptive Stats Display (Priority: P2)

**Goal**: Stats shown on the celebration screen adapt based on exercise types — no irrelevant metrics displayed.

**Independent Test**: Complete a strength-only workout → only weight/sets/reps shown. Complete a bodyweight-only workout → only sets/reps shown. Complete a cardio workout → only distance shown. Complete a mixed workout → all relevant stats shown. Duration and workout count always show.

### Implementation for User Story 2

- [ ] T006 [US2] Update `CelebrationView` stat rendering in `Kiln/Views/Workout/CelebrationView.swift` to use equipment category flags instead of simple non-zero value checks. Show total weight only when `data.hasWeightStats && data.totalVolume > 0`. Show total reps only when `data.hasRepsStats && data.totalReps > 0`. Show total distance only when `data.hasDistanceStats && data.totalDistance > 0`. Show total sets when `data.totalSets > 0` (always relevant if any sets completed). Duration and workout count always display regardless of flags.

**Checkpoint**: Test with different exercise types per the independent test above. Verify a reps-only workout (e.g., all bodyweight exercises) does NOT show total weight or distance.

---

## Phase 4: User Story 3 — Personal Record Highlights (Priority: P3)

**Goal**: Exercises where the user set a new all-time best single-set volume (weight × reps) are highlighted on the celebration screen.

**Independent Test**: Complete a workout where one exercise has a set exceeding all historical sets for that exercise → PR is highlighted. Complete a workout with no PRs → no PR section shown.

### Implementation for User Story 3

- [ ] T007 [US3] Add `computePersonalRecords(workout:context:)` method to `WorkoutSessionManager` in `Kiln/Services/WorkoutSessionManager.swift`. For each exercise in the workout, find the best completed set by volume (weight × reps). Then query all historical `WorkoutSet` records for sets belonging to the same `Exercise` (by exercise name match) in completed workouts (excluding the current workout). Compare best current set volume against best historical set volume. If current > historical (or no history exists with weight data), create a `PersonalRecord` with exerciseName, formatted newBest ("135 lbs × 10"), and formatted previousBest. Call this method inside `computeCelebrationData(context:)` and assign result to `personalRecords`.

- [ ] T008 [US3] Add personal records section to `CelebrationView` in `Kiln/Views/Workout/CelebrationView.swift`. Conditionally render below the stats grid only when `data.personalRecords` is non-empty. Show a "Personal Records" header with a trophy/flame icon. List each PR as a card showing exercise name, new best, and previous best (if available). Use `DesignSystem.Colors.success` (amber/gold) for PR highlight accent. Animate PR cards in with the same staggered spring pattern, appearing after stat cards.

**Checkpoint**: Create a workout with a set that exceeds the exercise's historical best → PR appears on celebration screen. Verify a workout with no PRs does not show the PR section.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Edge case handling and final validation

- [ ] T009 Verify edge cases across `CelebrationView` and `computeCelebrationData()`: (1) Zero completed sets — celebration shows with "0" for applicable stats and duration still displays, (2) First-ever workout — displays "1st workout" with correct ordinal, (3) Duration-only exercises (e.g., planks) — shows only duration and total sets, no weight/reps/distance, (4) App backgrounded while celebration visible — screen persists on return.

- [ ] T010 Run all 7 quickstart.md validation scenarios: (1) strength workout via Finish, (2) strength workout via Finish & Update Template, (3) bodyweight-only workout, (4) cardio workout, (5) mixed workout, (6) first workout, (7) workout with zero completed sets.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **User Story 1 (Phase 2)**: Depends on Phase 1 (T001 must complete first)
- **User Story 2 (Phase 3)**: Depends on Phase 2 (US1 must be complete — builds on CelebrationView)
- **User Story 3 (Phase 4)**: Depends on Phase 2 (US1 must be complete — adds PR section to CelebrationView). Independent of US2.
- **Polish (Phase 5)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 1) — no dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 (refines the stat display created in US1)
- **User Story 3 (P3)**: Depends on US1 (adds a section to CelebrationView created in US1). Independent of US2.

### Within Each User Story

- Models/data types before service logic
- Service logic before views
- Views before integration (ContentView wiring)
- Integration before xcodegen

### Parallel Opportunities

Within US1:
- T002 (WorkoutSessionManager changes) and T003 (CelebrationView creation) are in different files and can run in parallel
- T004 (ContentView wiring) depends on both T002 and T003
- T005 (xcodegen) depends on T003 (new file must exist)

Within US3:
- T007 (PR computation) and T008 (PR view) are in different files but T008 depends on T007's data shape

---

## Parallel Example: User Story 1

```text
# These two tasks can run in parallel (different files, no cross-dependency):
Task T002: "Add celebrationData property and computeCelebrationData() to WorkoutSessionManager.swift"
Task T003: "Create CelebrationView in CelebrationView.swift"

# Then sequentially:
Task T004: "Add .fullScreenCover to ContentView.swift" (depends on T002 + T003)
Task T005: "Run xcodegen generate" (depends on T003)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001)
2. Complete Phase 2: User Story 1 (T002–T005)
3. **STOP and VALIDATE**: Test celebration screen with a strength workout
4. Working celebration screen with all non-zero stats displayed

### Incremental Delivery

1. T001 → Foundation ready
2. T002–T005 → US1 complete → Celebration screen works for all workout types (shows all non-zero stats)
3. T006 → US2 complete → Stats adapt based on exercise equipment categories
4. T007–T008 → US3 complete → Personal records highlighted
5. T009–T010 → Polish → All edge cases verified

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No new SwiftData schema changes — CelebrationData is ephemeral (not persisted)
- xcodegen auto-discovers files via directory glob, but `xcodegen generate` must run to update the project
- The `personalRecords` field is an empty array until US3 is implemented — this is by design
