# Tasks: Live Activity Lock Screen Workout

**Input**: Design documents from `/specs/003-live-activity/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: No test tasks generated (not requested in feature specification; manual on-device testing per quickstart.md).

**Organization**: Tasks are grouped by user story. US3 (Lifecycle) is implemented before US1/US2 because the Live Activity must exist before it can be interacted with.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create widget extension target, directory structure, project configuration, and shared assets

- [ ] T001 Create directory structure: `Kiln/Shared/`, `Kiln/Intents/`, `KilnWidgets/`, `KilnWidgets/Views/`, `KilnWidgets/Assets.xcassets/`
- [ ] T002 Create entitlements file for main app with App Groups capability (`group.com.isabelgwara.Kiln`) in `Kiln/Kiln.entitlements`
- [ ] T003 [P] Create entitlements file for widget extension with same App Groups capability in `KilnWidgets/KilnWidgets.entitlements`
- [ ] T004 [P] Create widget extension Info.plist with NSExtension/NSExtensionPointIdentifier for WidgetKit in `KilnWidgets/Info.plist`
- [ ] T005 Update `project.yml` to add KilnWidgets app-extension target (sources: KilnWidgets + Kiln/Shared, entitlements for both targets, NSSupportsLiveActivities in Kiln Info.plist, embed KilnWidgets in Kiln target)
- [ ] T006 Create widget asset catalog with DesignSystem color tokens (primary #BF3326, background #F5F0EB, textPrimary #1A1A1A, textSecondary #6B5B4F, timerBackground #FDE8D8, surface #FFFFFF, destructive #94291F) and brick_icon in `KilnWidgets/Assets.xcassets/`
- [ ] T007 Run `xcodegen generate` to regenerate `Kiln.xcodeproj` with both targets and verify project opens in Xcode without errors

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared data types, service layer, and widget bundle that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Create `WorkoutActivityAttributes` struct conforming to `ActivityAttributes` with static fields (workoutName: String, workoutStartedAt: Date) and nested `ContentState` struct with all dynamic fields per data-model.md (exerciseName, setNumber, totalSetsInExercise, previousSetLabel, weight, reps, duration, distance, equipmentCategory, isRestTimerActive, restTimerEndDate, restTotalSeconds, isWorkoutComplete, exerciseIndex, totalExercises) in `Kiln/Shared/WorkoutActivityAttributes.swift`
- [ ] T009 [P] Create intent struct declarations (no perform bodies) for CompleteSetIntent, AdjustWeightIntent (with delta: Double parameter), AdjustRepsIntent (with delta: Int parameter), and SkipRestIntent — all conforming to AppIntent with isDiscoverable=false, openAppWhenRun=false — in `Kiln/Shared/WorkoutLiveActivityIntents.swift`
- [ ] T010 [P] Add `equipmentCategory` computed property to `EquipmentType` enum that maps 9 cases to 5 display categories ("weightReps", "repsOnly", "duration", "distance", "weightDistance") per the equipment category mapping table in data-model.md, in `Kiln/Models/EquipmentType.swift`
- [ ] T011 Add `findCurrentSet() -> (WorkoutExercise, WorkoutSet)?` method to `WorkoutSessionManager` that scans `activeWorkout.sortedExercises` then each exercise's `sortedSets` to return the first set where `isCompleted == false`, returning nil when all sets are complete, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T012 Create `LiveActivityService` with methods: `startActivity(workoutName:startedAt:initialState:) -> Activity<WorkoutActivityAttributes>?`, `updateActivity(_:state:alertConfiguration:)`, `endActivity(_:finalState:)`, and `buildContentState(from:sessionManager:)` that constructs ContentState from current WorkoutSessionManager state using findCurrentSet(), previous set formatting, and equipment category mapping, in `Kiln/Services/LiveActivityService.swift`
- [ ] T013 Create `KilnWidgetBundle` as @main WidgetBundle entry point containing a single `WorkoutLiveActivity` widget that uses `ActivityConfiguration(for: WorkoutActivityAttributes.self)` with a placeholder lock screen body and required Dynamic Island stubs (minimal — compactLeading/compactTrailing/minimal/expanded with basic text), plus `.widgetURL(URL(string: "kiln://active-workout"))` and `.contentMarginsDisabled()`, in `KilnWidgets/KilnWidgetBundle.swift`

**Checkpoint**: Project builds with both targets. Widget extension registers the Live Activity type. Shared types compile in both targets.

---

## Phase 3: User Story 3 - Live Activity Lifecycle (Priority: P2, implemented first as prerequisite)

**Goal**: The Live Activity automatically appears when a workout starts and disappears when it finishes or is discarded. Survives app termination.

**Independent Test**: Start a workout from a template → lock phone → verify Live Activity appears on lock screen. Finish workout in-app → verify Live Activity disappears.

### Implementation for User Story 3

- [ ] T014 [US3] Add `currentActivity: Activity<WorkoutActivityAttributes>?` and `liveActivityService: LiveActivityService` properties to `WorkoutSessionManager`, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T015 [US3] Add `startLiveActivity()` method to `WorkoutSessionManager` that calls `liveActivityService.startActivity()` with the active workout's name, startedAt, and initial ContentState built from findCurrentSet(), and stores the returned Activity reference in currentActivity, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T016 [US3] Hook `startLiveActivity()` call at the end of both `startWorkout(from:context:)` and `startEmptyWorkout(context:)` in `WorkoutSessionManager`, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T017 [US3] Add `endLiveActivity()` method to `WorkoutSessionManager` that calls `liveActivityService.endActivity()` with .immediate dismissal and clears currentActivity reference, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T018 [US3] Hook `endLiveActivity()` call in `finishWorkout(context:)`, `discardWorkout(context:)`, and `reset()` methods in `WorkoutSessionManager`, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T019 [US3] Add `reconnectLiveActivity()` method to `WorkoutSessionManager` that iterates `Activity<WorkoutActivityAttributes>.activities` to find an existing activity matching the current workout and re-stores it in currentActivity (for crash recovery and app relaunch scenarios), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T020 [US3] Hook `reconnectLiveActivity()` into the crash recovery flow: call it from `resumeInterruptedWorkout()` and from the `.onChange(of: scenePhase)` handler in `KilnApp.swift` when scenePhase becomes .active and a workout is in progress, in `Kiln/Services/WorkoutSessionManager.swift` and `Kiln/KilnApp.swift`

**Checkpoint**: Live Activity appears on lock screen when workout starts, disappears when finished/discarded, and reconnects after app relaunch.

---

## Phase 4: User Story 1 - Complete a Set from the Lock Screen (Priority: P1) MVP

**Goal**: User sees current exercise, previous set, weight/reps with +/- buttons, and a Complete button on the lock screen. Tapping Complete logs the set.

**Independent Test**: Start a workout → lock phone → on lock screen see exercise name, "55 lbs x 8" previous, weight/reps values with +/- → tap + on weight → value increments → tap Complete → set is marked complete in SwiftData.

### Implementation for User Story 1

- [ ] T021 [P] [US1] Build SetView (the "Set View" state from contracts/live-activity-states.md) as a SwiftUI view that accepts `ActivityViewContext<WorkoutActivityAttributes>` and renders: exercise name + equipment category label (top-left), "Set N of M" (top-right), "Exercise X of Y" + elapsed time via `Text(context.attributes.workoutStartedAt, style: .timer)` (second row), "PREVIOUS" label with previousSetLabel, conditionally-shown weight field with −/+ `Button(intent: AdjustWeightIntent(delta:))` buttons, conditionally-shown reps field with −/+ `Button(intent: AdjustRepsIntent(delta:))` buttons (field visibility based on equipmentCategory), and a primary "Complete Set" `Button(intent: CompleteSetIntent())`, all using widget asset catalog colors, in `KilnWidgets/Views/SetView.swift`
- [ ] T022 [P] [US1] Implement `LiveActivityIntent` conformance with `perform()` bodies for `CompleteSetIntent`, `AdjustWeightIntent`, and `AdjustRepsIntent` in the main app target. `CompleteSetIntent.perform()` calls `WorkoutSessionManager.shared.completeCurrentSetFromIntent()`. `AdjustWeightIntent.perform()` calls `adjustWeightFromIntent(delta:)`. `AdjustRepsIntent.perform()` calls `adjustRepsFromIntent(delta:)`. All return `.result()`, in `Kiln/Intents/WorkoutLiveActivityIntents+App.swift`
- [ ] T023 [P] [US1] Create stub `LiveActivityIntent` conformance with empty `perform()` bodies returning `.result()` for CompleteSetIntent, AdjustWeightIntent, and AdjustRepsIntent in the widget extension target, in `KilnWidgets/WorkoutLiveActivityIntents+Widget.swift`
- [ ] T024 [US1] Add `completeCurrentSetFromIntent()` method to `WorkoutSessionManager` that: finds the current set via `findCurrentSet()`, marks it as completed (isCompleted=true, completedAt=.now), saves context, starts rest timer with the exercise's defaultRestSeconds, updates lastCompletedSetId, and calls updateLiveActivity(), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T025 [US1] Add `adjustWeightFromIntent(delta:)` method to `WorkoutSessionManager` that: finds the current set, adjusts the appropriate field based on equipment category (weight ±1 for weightReps/weightDistance, seconds ±5 for duration, distance ±0.1 for distance), clamps to minimum 0, saves context, and calls updateLiveActivity(), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T026 [US1] Add `adjustRepsFromIntent(delta:)` method to `WorkoutSessionManager` that: finds the current set, adjusts reps by delta (±1), clamps to minimum 0, saves context, and calls updateLiveActivity(), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T027 [US1] Add `updateLiveActivity()` method to `WorkoutSessionManager` that builds a fresh ContentState via `liveActivityService.buildContentState()` and calls `liveActivityService.updateActivity()` on currentActivity (no-op if currentActivity is nil), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T028 [US1] Wire SetView into the `ActivityConfiguration` lock screen body in `KilnWidgetBundle.swift` — render SetView when `!context.state.isRestTimerActive && !context.state.isWorkoutComplete`, in `KilnWidgets/KilnWidgetBundle.swift`

**Checkpoint**: User can view set info and tap +/-, Complete on lock screen. Set is persisted in SwiftData. In-app view reflects changes.

---

## Phase 5: User Story 2 - Rest Timer on Lock Screen with Sound Alert (Priority: P1)

**Goal**: After completing a set, the lock screen shows a countdown timer. When it expires, a sound plays and the next set appears. User can skip the timer.

**Independent Test**: Complete a set from lock screen → timer countdown appears → wait for expiry → sound plays → next set shown. Also: tap Skip Rest → timer ends → next set shown immediately.

### Implementation for User Story 2

- [ ] T029 [P] [US2] Build TimerView (the "Timer View" state from contracts/live-activity-states.md) as a SwiftUI view that accepts `ActivityViewContext<WorkoutActivityAttributes>` and renders: exercise name + next set position (top row), elapsed time, large countdown via `Text(timerInterval: Date.now...context.state.restTimerEndDate, countsDown: true)` with monospaced digit font, a progress bar (using restTotalSeconds and restTimerEndDate to calculate progress), "REST" label, and a "Skip Rest" `Button(intent: SkipRestIntent())`, in `KilnWidgets/Views/TimerView.swift`
- [ ] T030 [P] [US2] Add `LiveActivityIntent` conformance with `perform()` body for `SkipRestIntent` in the main app target — calls `WorkoutSessionManager.shared.skipRestTimerFromIntent()` and returns `.result()`, in `Kiln/Intents/WorkoutLiveActivityIntents+App.swift`
- [ ] T031 [P] [US2] Add stub `LiveActivityIntent` conformance for `SkipRestIntent` in the widget extension target, returning `.result()`, in `KilnWidgets/WorkoutLiveActivityIntents+Widget.swift`
- [ ] T032 [US2] Add `onTimerExpired: (() -> Void)?` callback property to `RestTimerService` and invoke it from the existing `tick()` method when remainingSeconds reaches 0 (alongside the existing haptic feedback), in `Kiln/Services/RestTimerService.swift`
- [ ] T033 [US2] Set `restTimer.onTimerExpired` in `WorkoutSessionManager.init()` to a closure that calls `updateLiveActivity()` with an `AlertConfiguration(title: "Rest Complete", body: "Time for your next set!", sound: .default)` to play the notification sound, then advances ContentState to show the next incomplete set (or completion state), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T034 [US2] Add `skipRestTimerFromIntent()` method to `WorkoutSessionManager` that stops the rest timer (`restTimer.stop()`), clears lastCompletedSetId, and calls `updateLiveActivity()` to transition the Live Activity from Timer View to Set View (next set) or Complete View, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T035 [US2] Update `completeCurrentSetFromIntent()` (from T024) to set `isRestTimerActive=true` and `restTimerEndDate` in the ContentState update so the Live Activity transitions to Timer View after set completion, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T036 [US2] Wire TimerView into the `ActivityConfiguration` lock screen body in `KilnWidgetBundle.swift` — render TimerView when `context.state.isRestTimerActive && !context.state.isWorkoutComplete`, in `KilnWidgets/KilnWidgetBundle.swift`

**Checkpoint**: Full set-to-set workflow works from lock screen: complete set → timer counts down → sound on expiry → next set shown. Skip rest works.

---

## Phase 6: User Story 4 - Workout Completion from Lock Screen (Priority: P2)

**Goal**: When all sets are complete, the lock screen shows a "Workout Complete" summary. Tapping it opens the app.

**Independent Test**: Complete all sets in a workout via lock screen → after last timer expires → lock screen shows workout name, elapsed time, "All sets complete" → tap → app opens to active workout view.

### Implementation for User Story 4

- [ ] T037 [P] [US4] Build CompleteView (the "Complete View" state from contracts/live-activity-states.md) as a SwiftUI view that accepts `ActivityViewContext<WorkoutActivityAttributes>` and renders: fire icon, "All Sets Complete" text, workout name + elapsed time (from attributes.workoutStartedAt), "Tap to open app and finish" instruction, using widget asset catalog colors, in `KilnWidgets/Views/CompleteView.swift`
- [ ] T038 [US4] Update `buildContentState()` in `LiveActivityService` to set `isWorkoutComplete=true` when `findCurrentSet()` returns nil (all sets complete), in `Kiln/Services/LiveActivityService.swift`
- [ ] T039 [US4] Wire CompleteView into the `ActivityConfiguration` lock screen body in `KilnWidgetBundle.swift` — render CompleteView when `context.state.isWorkoutComplete`, in `KilnWidgets/KilnWidgetBundle.swift`
- [ ] T040 [US4] Ensure `widgetURL(URL(string: "kiln://active-workout"))` is set on the ActivityConfiguration (from T013) so tapping the Complete View opens the app. Add `.onOpenURL` handler in `KilnApp.swift` that navigates to the active workout tab when receiving the `kiln://active-workout` URL scheme, in `Kiln/KilnApp.swift`

**Checkpoint**: Completing all sets shows workout complete state on lock screen. Tapping opens the app.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Equipment type variations, sync edge cases, and documentation updates

- [ ] T041 Verify SetView handles all 5 equipment categories correctly: test with a workout containing barbell (weight+reps), reps-only (bodyweight), duration (plank), distance (running), and weighted-distance exercises — confirm the Live Activity shows only the relevant input fields and +/- buttons for each, in `KilnWidgets/Views/SetView.swift`
- [ ] T042 [P] Hook `updateLiveActivity()` into the existing in-app `completeSet(_:context:)` method in WorkoutSessionManager so that completing a set from within the app also updates the Live Activity (bidirectional sync), in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T043 [P] Hook `updateLiveActivity()` calls after any in-app changes that affect the current set: adding/removing exercises, adding/removing sets, and editing weight/reps values from the in-app UI, in `Kiln/Services/WorkoutSessionManager.swift`
- [ ] T044 Add `previousSetLabel` formatting helper to `LiveActivityService.buildContentState()` that reads the pre-fill data for the current set and formats it as "55 lbs x 8" (weight+reps), "x 8" (reps only), "0.5 mi" (distance), "60s" (duration) — matching the existing PREVIOUS column format in SetRowView, in `Kiln/Services/LiveActivityService.swift`
- [ ] T045 Update CLAUDE.md to document new architecture: KilnWidgets target, Kiln/Shared directory, LiveActivityService, intent split pattern, App Groups, and `xcodegen generate` requirement after changes, in `CLAUDE.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US3 Lifecycle (Phase 3)**: Depends on Foundational — BLOCKS US1 and US2 (Live Activity must exist before interactions work)
- **US1 Set Completion (Phase 4)**: Depends on US3 Lifecycle
- **US2 Rest Timer (Phase 5)**: Depends on US1 (timer starts after set completion)
- **US4 Workout Complete (Phase 6)**: Depends on US1 and US2 (needs full set-to-set flow)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US3 (Lifecycle, P2)**: Implemented first as infrastructure prerequisite — no story dependencies
- **US1 (Set Completion, P1)**: Depends on US3 (needs a Live Activity to render the Set View and accept button interactions)
- **US2 (Rest Timer, P1)**: Depends on US1 (timer triggers from set completion; timer expiry advances to next set which requires Set View)
- **US4 (Workout Complete, P2)**: Depends on US2 (completion state appears after last timer expires)

### Within Each User Story

- Shared types / intent declarations before views and perform() bodies
- Views and intent implementations can be parallel (different files, different targets)
- SessionManager methods before wiring into KilnWidgetBundle
- Wire views into ActivityConfiguration last

### Parallel Opportunities

**Phase 1**: T002, T003, T004 can all run in parallel (independent files)
**Phase 2**: T009, T010 can run in parallel with each other (independent files); T008 is independent of T009/T010
**Phase 4**: T021 (SetView), T022 (app intents), T023 (widget stubs) can all run in parallel
**Phase 5**: T029 (TimerView), T030 (app intent), T031 (widget stub) can all run in parallel
**Phase 7**: T042, T043 can run in parallel with each other

---

## Parallel Example: User Story 1

```bash
# Launch views and intents in parallel (different files, different targets):
Task: "Build SetView in KilnWidgets/Views/SetView.swift"               # T021
Task: "Implement intent perform() in Kiln/Intents/...+App.swift"       # T022
Task: "Create intent stubs in KilnWidgets/...+Widget.swift"            # T023

# Then sequentially: SessionManager methods → wire into ActivityConfiguration
Task: "Add completeCurrentSetFromIntent() to WorkoutSessionManager"    # T024
Task: "Add adjustWeightFromIntent() to WorkoutSessionManager"          # T025
Task: "Add adjustRepsFromIntent() to WorkoutSessionManager"            # T026
Task: "Add updateLiveActivity() to WorkoutSessionManager"              # T027
Task: "Wire SetView into KilnWidgetBundle.swift"                       # T028
```

---

## Implementation Strategy

### MVP First (US3 + US1 — Lifecycle + Set Completion)

1. Complete Phase 1: Setup (project configuration)
2. Complete Phase 2: Foundational (shared types, services, widget bundle)
3. Complete Phase 3: US3 Lifecycle (Live Activity appears/disappears)
4. Complete Phase 4: US1 Set Completion (display set data, +/-, Complete button)
5. **STOP and VALIDATE**: Live Activity shows on lock screen, user can adjust values and complete sets
6. This is a usable MVP even without the timer view — sets are logged from lock screen

### Incremental Delivery

1. Setup + Foundational → Project builds with both targets
2. Add US3 Lifecycle → Live Activity appears/disappears with workout
3. Add US1 Set Completion → Full set logging from lock screen (MVP!)
4. Add US2 Rest Timer → Complete set-to-set workflow with countdown and sound
5. Add US4 Workout Complete → Full workout flow with completion state
6. Polish → Equipment type coverage, sync edge cases, documentation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US3 is P2 in the spec but implemented first because it's a prerequisite for US1/US2
- All on-device testing — Live Activities require physical iPhone 13
- Intent split pattern is critical: shared declarations, app-only perform(), widget-only stubs
- Always run `xcodegen generate` after modifying project.yml
