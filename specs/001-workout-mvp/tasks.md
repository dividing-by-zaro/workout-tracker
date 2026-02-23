# Tasks: Workout MVP

**Input**: Design documents from `/specs/001-workout-mvp/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, quickstart.md

**Tests**: Not included (not explicitly requested). Test files noted in plan.md (CSVImportTests, PreFillTests, WorkoutSessionTests) can be added in a follow-up pass.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Paths are relative to `Kiln/` (the Xcode project root)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create Xcode project and establish directory structure

- [x] T001 Create Xcode project "Kiln" with SwiftUI lifecycle, iOS 17+ deployment target, and directory structure per plan.md (`Models/`, `Views/Workout/`, `Views/Templates/`, `Views/History/`, `Views/Profile/`, `Services/`, `Design/`)
- [x] T002 Configure KilnApp.swift with SwiftData ModelContainer (autosave disabled), create @State WorkoutSessionManager, and inject it via .environment()

---

## Phase 2: Foundational (All Data Models + Design System + Tab Shell)

**Purpose**: Define all SwiftData @Model entities and the design system. These are shared across every user story and MUST be complete before story work begins.

- [x] T003 [P] Create ExerciseType enum (strength, cardio, bodyweight) in Kiln/Models/ExerciseType.swift
- [x] T004 [P] Create DesignSystem with colors, typography, and spacing constants in Kiln/Design/DesignSystem.swift
- [x] T005 [P] Create Exercise @Model with fields (id, name, exerciseType, defaultRestSeconds) and unique constraint on name in Kiln/Models/Exercise.swift
- [x] T006 [P] Create WorkoutTemplate @Model with fields (id, name, createdAt, lastUsedAt) and @Relationship to exercises with cascade delete in Kiln/Models/WorkoutTemplate.swift
- [x] T007 [P] Create TemplateExercise @Model with fields (id, order, defaultSets) and relationships to Exercise and WorkoutTemplate in Kiln/Models/TemplateExercise.swift
- [x] T008 [P] Create Workout @Model with fields (id, name, startedAt, completedAt, durationSeconds, isInProgress, templateId) and @Relationship to exercises with cascade delete in Kiln/Models/Workout.swift
- [x] T009 [P] Create WorkoutExercise @Model with fields (id, order) and relationships to Exercise, Workout, and sets with cascade delete in Kiln/Models/WorkoutExercise.swift
- [x] T010 [P] Create WorkoutSet @Model with fields (id, order, weight, reps, distance, seconds, rpe, isCompleted, completedAt) and relationship to WorkoutExercise in Kiln/Models/WorkoutSet.swift
- [x] T011 Register all @Model types in ModelContainer schema in Kiln/KilnApp.swift
- [x] T012 [P] Create ContentView with 3-tab TabView (Workout, History, Profile) using SF Symbols and bottom tab bar in Kiln/Views/ContentView.swift

**Checkpoint**: All models defined, tab shell visible. Ready for user story implementation.

---

## Phase 3: User Story 1 — Start and Complete a Workout from a Template (Priority: P1) MVP

**Goal**: One-tap template start, pre-filled sets, set completion with rest timer, finish workout flow.

**Independent Test**: Start a template workout, complete all sets with timer, verify workout saved with correct data.

### Services for User Story 1

- [x] T013 [P] [US1] Implement PreFillService: query most recent workout containing a given exercise and return per-set weight/reps data in Kiln/Services/PreFillService.swift
- [x] T014 [P] [US1] Implement RestTimerService: schedule/cancel UNUserNotificationCenter local notifications, persist timer end date to UserDefaults, provide wall-clock-derived countdown, handle foreground haptic+audio alert in Kiln/Services/RestTimerService.swift
- [x] T015 [US1] Implement WorkoutSessionManager (@Observable): manage active workout reference, start workout from template (create Workout + WorkoutExercises + pre-filled WorkoutSets), finish workout, track elapsed time, own RestTimerService instance in Kiln/Services/WorkoutSessionManager.swift

### Views for User Story 1

- [x] T016 [P] [US1] Create TemplateCardView showing template name, exercise summary list, and last-used date in Kiln/Views/Workout/TemplateCardView.swift
- [x] T017 [US1] Create StartWorkoutView with LazyVGrid of TemplateCardViews (@Query templates) and "Start an Empty Workout" button in Kiln/Views/Workout/StartWorkoutView.swift
- [x] T018 [US1] Create SetRowView displaying set number, previous performance label, editable weight field, editable reps field, and completion checkmark button; adapt display based on ExerciseType (strength: weight+reps, cardio: distance+time, bodyweight: reps only) in Kiln/Views/Workout/SetRowView.swift
- [x] T019 [US1] Create ExerciseCardView showing exercise name, rest timer duration, and a list of SetRowViews for each WorkoutSet in Kiln/Views/Workout/ExerciseCardView.swift
- [x] T020 [US1] Create RestTimerView showing countdown display with remaining seconds, tap-to-adjust duration, and visual progress indicator in Kiln/Views/Workout/RestTimerView.swift
- [x] T021 [US1] Create ActiveWorkoutView with scrollable exercise list (ExerciseCardViews), RestTimerView overlay/banner, elapsed time display, and "Finish Workout" button in Kiln/Views/Workout/ActiveWorkoutView.swift

### Integration for User Story 1

- [x] T022 [US1] Wire Workout tab in ContentView to show StartWorkoutView when no workout is active and ActiveWorkoutView when sessionManager.isWorkoutInProgress is true
- [x] T023 [US1] Implement set completion flow: on checkmark tap, mark set isCompleted=true, set completedAt, persist via explicit modelContext.save(), trigger rest timer start in WorkoutSessionManager
- [x] T024 [US1] Request notification permission on first workout start and ensure rest timer notifications fire in background/locked state

**Checkpoint**: Can start a template workout, complete sets with pre-fill and rest timer, finish workout. US1 fully functional.

---

## Phase 4: User Story 2 — Modify a Workout In-Progress (Priority: P2)

**Goal**: Add exercises, swap exercises, add/remove sets, edit completed set values mid-workout.

**Independent Test**: Start a workout, add an exercise, swap an exercise, remove a set, add a set, edit weight/reps on a completed set, verify all changes persist.

- [x] T025 [P] [US2] Create ExercisePickerView with searchable list of all exercises (@Query), selection callback, and "Create New Exercise" option in Kiln/Views/Workout/ExercisePickerView.swift
- [x] T026 [US2] Add "Add Exercise" button to ActiveWorkoutView that presents ExercisePickerView and appends selected exercise as new WorkoutExercise with default sets in Kiln/Views/Workout/ActiveWorkoutView.swift
- [x] T027 [US2] Add swap/replace action to ExerciseCardView that presents ExercisePickerView and replaces the current exercise (preserving position, resetting sets) in Kiln/Views/Workout/ExerciseCardView.swift
- [x] T028 [US2] Add "Add Set" and swipe-to-delete-set functionality to ExerciseCardView; new set pre-fills from the previous set's weight/reps in Kiln/Views/Workout/ExerciseCardView.swift
- [x] T029 [US2] Enable inline editing of weight/reps on completed sets by making fields tappable/editable and persisting changes immediately via modelContext.save() in Kiln/Views/Workout/SetRowView.swift

**Checkpoint**: Full mid-workout modification capability. US2 independently testable.

---

## Phase 5: User Story 3 — Recover an Interrupted Workout (Priority: P3)

**Goal**: Zero data loss on crash/force-quit. Workout and timer state fully restored on relaunch.

**Independent Test**: Start a workout, complete several sets, force-quit the app, relaunch, verify workout is fully restored with correct timer state.

- [x] T030 [US3] On app launch, query for Workout with isInProgress==true in WorkoutSessionManager and restore it as the active workout with all completed sets intact in Kiln/Services/WorkoutSessionManager.swift
- [x] T031 [US3] Persist rest timer end date to UserDefaults on timer start and clear on timer completion/cancellation in Kiln/Services/RestTimerService.swift
- [x] T032 [US3] On app launch with interrupted workout, present resume/discard prompt in the Workout tab before showing the active workout view in Kiln/Views/Workout/ActiveWorkoutView.swift
- [x] T033 [US3] On scenePhase change to .active, call syncFromPersistedState() on RestTimerService to recalculate countdown from persisted end date in Kiln/KilnApp.swift

**Checkpoint**: Crash recovery fully functional. US3 independently testable.

---

## Phase 6: User Story 4 — Create and Manage Workout Templates (Priority: P4)

**Goal**: Create, edit, and delete workout templates from the Workout tab.

**Independent Test**: Create a new template, add exercises, save it, verify it appears in template grid, start a workout from it.

- [x] T034 [P] [US4] Create TemplateExerciseRow showing exercise name, default sets stepper, and drag handle for reordering in Kiln/Views/Templates/TemplateExerciseRow.swift
- [x] T035 [US4] Create TemplateEditorView with name field, exercise list (TemplateExerciseRows with reorder support), "Add Exercise" button using ExercisePickerView, and Save/Cancel actions in Kiln/Views/Templates/TemplateEditorView.swift
- [x] T036 [US4] Add "+ Template" button to StartWorkoutView that presents TemplateEditorView as a sheet in Kiln/Views/Workout/StartWorkoutView.swift
- [x] T037 [US4] Add context menu to TemplateCardView with "Edit" (presents TemplateEditorView) and "Delete" (with confirmation alert, cascade deletes TemplateExercises) actions in Kiln/Views/Workout/TemplateCardView.swift

**Checkpoint**: Full template CRUD. US4 independently testable.

---

## Phase 7: User Story 5 — View Workout History (Priority: P5)

**Goal**: Chronological list of past workouts with drill-down to full detail.

**Independent Test**: Complete a workout, navigate to History, verify it appears with correct summary, tap to see full detail.

- [x] T038 [P] [US5] Create WorkoutCardView showing workout name, date, duration, total volume (sum of weight x reps), and exercise summary (exercise names with best set) in Kiln/Views/History/WorkoutCardView.swift
- [x] T039 [P] [US5] Create WorkoutDetailView showing full workout: every exercise with all sets (weight, reps, distance, seconds, RPE as applicable), using prefetching for exercises and sets in Kiln/Views/History/WorkoutDetailView.swift
- [x] T040 [US5] Create HistoryListView with @Query workouts (completed only, sorted most-recent-first) displaying WorkoutCardViews and NavigationLink to WorkoutDetailView in Kiln/Views/History/HistoryListView.swift
- [x] T041 [US5] Wire HistoryListView into the History tab in ContentView with NavigationStack in Kiln/Views/ContentView.swift

**Checkpoint**: History tab fully functional. US5 independently testable.

---

## Phase 8: User Story 6 — Minimal Profile Screen (Priority: P6)

**Goal**: Read-only profile with name, photo, workout count, and workouts-per-week chart.

**Independent Test**: Complete a few workouts, navigate to Profile, verify count and chart reflect accurate data.

- [x] T042 [P] [US6] Create WorkoutsPerWeekChart using Swift Charts BarMark, aggregating @Query workout data by ISO week for the last 8 weeks in Kiln/Views/Profile/WorkoutsPerWeekChart.swift
- [x] T043 [US6] Create ProfileView with hardcoded name/photo, total workout count from @Query, and WorkoutsPerWeekChart in Kiln/Views/Profile/ProfileView.swift
- [x] T044 [US6] Wire ProfileView into the Profile tab in ContentView in Kiln/Views/ContentView.swift

**Checkpoint**: Profile tab fully functional. US6 independently testable.

---

## Phase 9: User Story 7 — Import Strong Workout History (Priority: P7)

**Goal**: Import Strong CSV, create all workout records, auto-create two templates.

**Independent Test**: Import strong_workouts.csv, verify all 78+ workouts appear in History with correct data, verify two templates created, verify Profile count and chart.

- [x] T045 [US7] Implement CSVImportService as @ModelActor: parse Strong CSV (10 columns), group rows by Date+WorkoutName into Workouts, group by ExerciseName into WorkoutExercises, create WorkoutSets; infer ExerciseType from data (distance+seconds→cardio, weight>0→strength, else→bodyweight); save in batches of ~500; skip and count invalid rows in Kiln/Services/CSVImportService.swift
- [x] T046 [US7] Implement template auto-creation in CSVImportService: after import, find most recent occurrence of "New Legs/full Body A" and "New Legs/full Body B", create WorkoutTemplate + TemplateExercises with exercise list and set counts from those workouts in Kiln/Services/CSVImportService.swift
- [x] T047 [US7] Add CSV import trigger UI: a button in ProfileView (or a dedicated settings section) that opens a document picker for .csv files and invokes CSVImportService in Kiln/Views/Profile/ProfileView.swift
- [x] T048 [US7] Display import progress indicator and completion summary (workouts created, rows imported, rows skipped) as an alert or sheet in Kiln/Views/Profile/ProfileView.swift

**Checkpoint**: CSV import fully functional. US7 independently testable.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases and hardening that span multiple user stories

- [x] T049 [P] Add guard in WorkoutSessionManager to prevent starting a second workout while one is in-progress; present the active workout with an option to discard first per edge case spec in Kiln/Services/WorkoutSessionManager.swift
- [x] T050 [P] Add discard workout confirmation dialog; skip confirmation if zero sets completed per edge case spec in Kiln/Views/Workout/ActiveWorkoutView.swift
- [x] T051 [P] Handle rest timer cancellation when next set is completed before timer expires: cancel pending notification and start new timer in Kiln/Services/RestTimerService.swift
- [x] T052 Ensure all set completion writes use SwiftData atomic transaction {} to guarantee zero partial writes on crash in Kiln/Services/WorkoutSessionManager.swift
- [x] T053 Run quickstart.md verification checklist end-to-end and fix any issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — BLOCKS US2 and US3
- **US2 (Phase 4)**: Depends on US1 (adds to active workout views)
- **US3 (Phase 5)**: Depends on US1 (recovery requires workout persistence to exist)
- **US4 (Phase 6)**: Depends on Phase 2 only — can run in parallel with US1
- **US5 (Phase 7)**: Depends on Phase 2 only — can run in parallel with US1
- **US6 (Phase 8)**: Depends on Phase 2 only — can run in parallel with US1
- **US7 (Phase 9)**: Depends on Phase 2 only — can run in parallel with US1
- **Polish (Phase 10)**: Depends on all user stories being complete

### User Story Dependencies

```text
Phase 1 (Setup)
  └─→ Phase 2 (Foundational)
        ├─→ US1 (P1) ─→ US2 (P2)
        │             └─→ US3 (P3)
        ├─→ US4 (P4)  ← independent
        ├─→ US5 (P5)  ← independent
        ├─→ US6 (P6)  ← independent
        └─→ US7 (P7)  ← independent
                          └─→ Phase 10 (Polish)
```

### Within Each User Story

- Services before views
- Child views before parent views
- Integration/wiring tasks last

### Parallel Opportunities

- Phase 2: All model files (T003–T010) and DesignSystem (T004) can be written in parallel
- US1: PreFillService (T013) and RestTimerService (T014) in parallel; TemplateCardView (T016) in parallel with services
- US4+US5+US6+US7: All four stories can proceed in parallel after Phase 2
- US2 and US3: Can proceed in parallel after US1

---

## Parallel Example: Phase 2 (Foundational)

```bash
# All model files in parallel:
Task: "Create ExerciseType enum in Kiln/Models/ExerciseType.swift"
Task: "Create Exercise @Model in Kiln/Models/Exercise.swift"
Task: "Create WorkoutTemplate @Model in Kiln/Models/WorkoutTemplate.swift"
Task: "Create TemplateExercise @Model in Kiln/Models/TemplateExercise.swift"
Task: "Create Workout @Model in Kiln/Models/Workout.swift"
Task: "Create WorkoutExercise @Model in Kiln/Models/WorkoutExercise.swift"
Task: "Create WorkoutSet @Model in Kiln/Models/WorkoutSet.swift"
Task: "Create DesignSystem in Kiln/Design/DesignSystem.swift"
Task: "Create ContentView with TabView in Kiln/Views/ContentView.swift"

# Then sequentially:
Task: "Register all models in ModelContainer in Kiln/KilnApp.swift"
```

## Parallel Example: Independent Stories After Phase 2

```bash
# These four stories can run in parallel (different files, no cross-dependencies):
Story US4: Template CRUD (Kiln/Views/Templates/*)
Story US5: History views (Kiln/Views/History/*)
Story US6: Profile views (Kiln/Views/Profile/*)
Story US7: CSV import (Kiln/Services/CSVImportService.swift + Profile import UI)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (all models + tab shell)
3. Complete Phase 3: User Story 1 (template start + set completion + timer)
4. **STOP and VALIDATE**: Test US1 independently — start template, complete sets, finish workout
5. Demo-ready: Core workout logging works

### Incremental Delivery

1. Setup + Foundational → tab shell with models ready
2. US1 → Core workout flow (MVP!)
3. US2 → Mid-workout modifications
4. US3 → Crash recovery (zero data loss)
5. US4 → Template management
6. US5 → History viewing
7. US6 → Profile screen
8. US7 → Strong CSV import (populates all data)
9. Polish → Edge cases and hardening

### Suggested MVP Scope

**US1 alone** is a viable MVP: start a workout from a template, complete sets with pre-fill and rest timer, finish and save. All other stories add value incrementally.
