# Tasks: Exercise History Browser

**Input**: Design documents from `/specs/010-exercise-history/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks grouped by user story for independent implementation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Design system additions and tab bar infrastructure

- [x] T001 Add `exercises` icon constant (`"list.bullet"`) to `DesignSystem.Icon` in Kiln/Design/DesignSystem.swift
- [x] T002 Add Exercises tab (tag 2) to TabView in Kiln/Views/ContentView.swift — wrap placeholder `Text("Exercises")` in `NavigationStack`, shift Profile tab to tag 3, update `shouldSwitchToWorkoutTab` to still target tag 0

**Checkpoint**: App builds with 4 tabs, Exercises tab shows placeholder text, all other tabs still work

---

## Phase 2: User Story 1 — Browse All Exercises (Priority: P1) — MVP

**Goal**: Dedicated Exercises tab listing all exercises alphabetically with name and equipment type

**Independent Test**: Open Exercises tab → see all exercises sorted A→Z with equipment type labels

### Implementation for User Story 1

- [x] T003 [US1] Create ExerciseListView in Kiln/Views/Exercises/ExerciseListView.swift — `@Query(sort: \Exercise.name)` to list all exercises alphabetically, each row showing exercise name (`.textPrimary`) and equipment type (`.caption`, `.textSecondary`), using `NavigationLink` for each row (destination is placeholder `Text` for now), empty state when no exercises exist ("No exercises yet" centered message)
- [x] T004 [US1] Wire ExerciseListView into ContentView tab in Kiln/Views/ContentView.swift — replace placeholder `Text("Exercises")` with `ExerciseListView()` inside the existing `NavigationStack`
- [x] T005 [US1] Run `xcodegen generate` to pick up new Kiln/Views/Exercises/ directory

**Checkpoint**: Exercises tab shows all exercises sorted alphabetically, each with name + equipment type. Empty state shows when no exercises exist. Navigation links are present but lead to placeholder.

---

## Phase 3: User Story 2 — View Exercise History (Priority: P1)

**Goal**: Tapping an exercise shows every past workout session where it was performed, with set details per equipment type

**Independent Test**: Tap any exercise → see all past workout dates with completed sets (weight/reps/distance/duration based on equipment type), most recent first. Exercises with no history show empty state.

### Implementation for User Story 2

- [x] T006 [US2] Create ExerciseHistoryView in Kiln/Views/Exercises/ExerciseHistoryView.swift — accepts an `Exercise` parameter, queries `WorkoutExercise` entities matching that exercise from finished workouts (`isInProgress == false`), groups by parent workout sorted by `startedAt` descending. Each workout session displayed as a card (date header + set rows). Set rows show equipment-type-aware formatting mirroring `WorkoutDetailView.setDetailLabel` logic (weight+reps, reps only, duration, distance, weighted bodyweight, weighted distance). Only completed sets (`isCompleted == true`) are shown. Empty state when no workout history exists ("No history yet" centered message). Use `DesignSystem.Colors`, `.cardShadow()`, grain overlay, fire light theme styling.
- [x] T007 [US2] Update ExerciseListView NavigationLink destination in Kiln/Views/Exercises/ExerciseListView.swift — replace placeholder `Text` with `ExerciseHistoryView(exercise:)` for each row
- [x] T008 [US2] Run `xcodegen generate` if needed for new file

**Checkpoint**: Full flow works — tap exercise → see all past workout sessions with correct set details. Empty state for exercises with no history. Equipment-type-specific formatting is correct.

---

## Phase 4: User Story 3 — Search Exercises (Priority: P2)

**Goal**: Search bar to filter exercises by name

**Independent Test**: Pull down on exercise list → type partial name → list filters to matching exercises. No matches → shows "No exercises found" message.

### Implementation for User Story 3

- [x] T009 [US3] Add `.searchable(text:prompt:)` modifier and search filtering to ExerciseListView in Kiln/Views/Exercises/ExerciseListView.swift — add `@State searchText`, computed `filteredExercises` property using `localizedCaseInsensitiveContains`, display "No exercises found" when search has no matches (distinct from empty-state when no exercises exist at all). Mirror the pattern from `ExercisePickerView`.

**Checkpoint**: Search works — partial name filters list, empty search shows all, no-match shows message.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [x] T010 Update CLAUDE.md project structure section to include `Exercises/` directory under `Views/` with `ExerciseListView.swift` and `ExerciseHistoryView.swift`
- [ ] T011 Manual validation: verify all 4 acceptance scenarios for US1, all 4 for US2, and both for US3 per spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on Phase 1 (T001, T002)
- **Phase 3 (US2)**: Depends on Phase 2 (T003 creates the file US2 modifies)
- **Phase 4 (US3)**: Depends on Phase 2 (T003 creates the file US3 modifies). Can run in parallel with Phase 3.
- **Phase 5 (Polish)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (Browse Exercises)**: Standalone after setup — creates the exercise list view
- **US2 (Exercise History)**: Depends on US1 (needs NavigationLink destinations in ExerciseListView)
- **US3 (Search)**: Depends on US1 (modifies ExerciseListView). Independent of US2.

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- US2 (T006) and US3 (T009) modify different files and can be developed in parallel after US1

---

## Parallel Example: Setup Phase

```text
# These touch different files and can run simultaneously:
Task T001: "Add exercises icon to DesignSystem.swift"
Task T002: "Add Exercises tab to ContentView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: US1 — Exercise List (T003, T004, T005)
3. **STOP and VALIDATE**: Exercises tab shows alphabetical list
4. Can ship as-is — provides exercise catalog value even without history

### Full Feature Delivery

1. Setup → US1 (exercise list) → US2 (exercise history) → US3 (search) → Polish
2. Each phase adds value without breaking previous phases
3. Total: 11 tasks across 5 phases

---

## Notes

- No new SwiftData models — all tasks read existing entities
- No backend changes — purely client-side feature
- `setDetailLabel` display logic should be extracted or mirrored from `WorkoutDetailView` (lines 59–102) for equipment-type-aware set formatting in `ExerciseHistoryView`
- `xcodegen generate` must run after creating new Swift files to update the Xcode project
