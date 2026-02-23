# Feature Specification: Workout MVP

**Feature Branch**: `001-workout-mvp`
**Created**: 2026-02-22
**Status**: Draft
**Input**: User description: "MVP workout screen with logging, templates, timers, and minimal history/profile. No live activity. Stay close to Strong's design. Bottom nav always visible."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start and Complete a Workout from a Template (Priority: P1)

Isabel opens the app and sees the Workout tab with her templates displayed as cards in a grid (similar to Strong's "Start Workout" screen). She taps her "New Legs/full Body A" template and the workout begins immediately — the Workout tab content is replaced by the active workout view. The bottom navigation bar remains visible throughout.

She sees her exercises listed vertically. Each exercise shows rows for each set, pre-filled with the weight and reps from the most recent workout where she performed each exercise (regardless of template). She performs her first set of Lat Pulldown (Cable) at 88 lb x 8 reps, matches the pre-filled values, and taps a single checkmark button to complete the set. A rest timer automatically starts counting down (e.g., 90 seconds). When the timer finishes, she hears an audio alert and feels a haptic buzz, even if her phone is locked or the app is in the background.

She works through all exercises and sets. If she lifted more or fewer reps, she edits the value inline before tapping complete. After her last set, she taps "Finish Workout." The workout is saved with duration, all exercises, sets, reps, weights, and the active workout view returns to the template selection screen.

**Why this priority**: This is the fundamental action the entire app exists to support. Without this, nothing else matters.

**Independent Test**: Can be fully tested by starting a template workout, completing all sets with timer, and verifying the workout is saved with correct data.

**Acceptance Scenarios**:

1. **Given** the Workout tab is showing templates, **When** I tap a template card, **Then** the active workout view appears immediately with all template exercises loaded and each set pre-filled with data from the most recent workout containing that exercise (set-by-set: set 1 shows previous set 1 data, etc.).
2. **Given** I am in an active workout viewing a set row, **When** I tap the checkmark/complete button, **Then** the set is marked complete, the data is persisted immediately, and the rest timer begins counting down.
3. **Given** a rest timer is running and I lock my phone or switch apps, **When** the timer reaches zero, **Then** I receive an audio alert and haptic notification.
4. **Given** I have completed all sets for all exercises, **When** I tap "Finish Workout", **Then** the workout is saved with the correct timestamp, duration, exercises, sets, reps, and weights, and the view returns to the template selection.
5. **Given** I am in an active workout, **When** I navigate to Profile or History via the bottom tab bar, **Then** those tabs display normally and my workout continues in the background without losing any data. When I tap the Workout tab again, I return to my in-progress workout.

---

### User Story 2 - Modify a Workout In-Progress (Priority: P2)

During a workout, Isabel realizes she wants to swap an exercise (the cable machine is taken) or add an extra exercise. She taps an "Add Exercise" button, sees a searchable list of exercises, and selects one — it appears in her workout. She can also swap an existing exercise by tapping it and choosing a replacement, or reorder exercises by dragging. She can change the number of sets for any exercise (add or remove set rows). She can also edit the weight or reps for any set before or after completing it.

**Why this priority**: Real workouts rarely go exactly according to plan. The ability to adapt mid-workout without friction is essential.

**Independent Test**: Start a workout, add an exercise, swap an exercise, remove a set, add a set, edit weight/reps on a completed set, and verify all changes persist correctly.

**Acceptance Scenarios**:

1. **Given** I am in an active workout, **When** I tap "Add Exercise", **Then** a searchable exercise picker appears. **When** I select an exercise, **Then** it is added to the bottom of my workout with default set/rep configuration.
2. **Given** I am viewing an exercise in my workout, **When** I tap a swap/replace action, **Then** I can search for and select a replacement exercise, and the new exercise takes the old one's position with fresh set rows.
3. **Given** I am viewing an exercise, **When** I tap "Add Set", **Then** a new set row appears pre-filled with the previous set's weight and reps.
4. **Given** I have already completed a set, **When** I tap the weight or reps value, **Then** I can edit it and the correction is persisted immediately.
5. **Given** I remove an exercise from the workout, **When** I finish the workout, **Then** the removed exercise does not appear in the saved record.

---

### User Story 3 - Recover an Interrupted Workout (Priority: P3)

Isabel is mid-workout when she receives a phone call, or her app is terminated by the OS, or she accidentally force-quits. When she reopens Kiln, the app detects the unfinished workout and immediately restores it — all completed sets are intact, the elapsed workout time is accurate, and if a rest timer was running, it either shows the remaining time or indicates it has already elapsed.

**Why this priority**: Data loss during a workout is the single worst user experience. This directly supports Constitution Principle I (Zero Data Loss).

**Independent Test**: Start a workout, complete several sets, force-quit the app, relaunch, and verify the workout is fully restored.

**Acceptance Scenarios**:

1. **Given** I have an active workout with 5 completed sets, **When** the app is terminated (force-quit, crash, or OS termination), **Then** on next launch the workout is restored with all 5 completed sets, correct weights, reps, and timestamps.
2. **Given** a rest timer was running at 45 seconds remaining when the app was terminated, **When** I relaunch the app 30 seconds later, **Then** the timer shows approximately 15 seconds remaining.
3. **Given** a rest timer was running when the app was terminated, **When** I relaunch the app after the timer would have expired, **Then** the timer shows as complete and an alert is presented (if the notification was missed).
4. **Given** I have an incomplete workout from a previous session, **When** I open the app, **Then** I am taken directly to the active workout view with a prompt to continue or discard.

---

### User Story 4 - Create and Manage Workout Templates (Priority: P4)

Isabel wants to create a new workout template. She taps "+ Template" from the Workout tab, gives it a name (e.g., "Push Day"), and adds exercises from the exercise picker. For each exercise she sets a default number of sets. She can also edit existing templates (rename, add/remove/reorder exercises) and delete templates she no longer uses.

**Why this priority**: Templates are required for the one-tap start (P1), but for the MVP, Isabel can start with her imported Strong templates. Template creation/editing is a secondary workflow.

**Independent Test**: Create a new template, add exercises, save it, verify it appears in the template grid, start a workout from it.

**Acceptance Scenarios**:

1. **Given** I am on the Workout tab, **When** I tap "+ Template", **Then** a template editor opens where I can name the template and add exercises.
2. **Given** I am editing a template, **When** I search for and add exercises, **Then** each exercise is added with a configurable default number of sets.
3. **Given** I have created a template, **When** I return to the Workout tab, **Then** the new template appears as a card in the grid showing its name and exercise list.
4. **Given** I tap the options menu on an existing template card, **When** I select "Edit", **Then** I can modify the template's name, exercises, and set counts.
5. **Given** I tap the options menu on a template card, **When** I select "Delete" and confirm, **Then** the template is removed from the grid. Past workouts that used this template are unaffected.

---

### User Story 5 - View Workout History (Priority: P5)

Isabel navigates to the History tab and sees a chronological list of her past workouts (most recent first), similar to Strong's History screen. Each workout card shows the workout name, date, duration, total volume (total weight lifted), and a summary of exercises with their best set. She can tap a workout to see its full detail — every exercise, every set, with weight, reps, distance, and seconds as applicable.

**Why this priority**: Seeing past performance is necessary for the pre-fill feature (P1) and gives workouts meaning beyond the moment. A minimal read-only history is sufficient for MVP.

**Independent Test**: Complete a workout, navigate to History, verify it appears at the top with correct summary data, tap it and verify full detail view.

**Acceptance Scenarios**:

1. **Given** I have completed workouts, **When** I tap the History tab, **Then** I see a scrollable list of workouts ordered most-recent-first, each showing name, date, duration, and total volume.
2. **Given** I am viewing the history list, **When** I tap a workout card, **Then** I see the full workout detail: every exercise with all sets, reps, weights, distance, and duration as applicable.
3. **Given** I just finished a workout, **When** I navigate to History, **Then** the workout I just completed appears at the top of the list.

---

### User Story 6 - Minimal Profile Screen (Priority: P6)

Isabel taps the Profile tab and sees her name, profile picture, and total workout count. A "Workouts Per Week" bar chart shows her activity over the past 8 weeks. This is a read-only screen for the MVP — no settings, no editing.

**Why this priority**: Provides motivation and a sense of progress, but is not core functionality for the MVP. The workouts/week chart is the most impactful single metric to display.

**Independent Test**: Complete a few workouts over different weeks, navigate to Profile, verify workout count and chart reflect accurate data.

**Acceptance Scenarios**:

1. **Given** I have completed 78 workouts, **When** I open the Profile tab, **Then** I see my name, profile picture, and "78 workouts" displayed.
2. **Given** I have workout data spanning multiple weeks, **When** I view the workouts-per-week chart, **Then** the chart shows accurate bars for the most recent 8 weeks.

---

### User Story 7 - Import Strong Workout History (Priority: P7)

Isabel imports her existing workout data from Strong via a CSV file. The import parses all fields (date, workout name, duration, exercise name, set order, weight, reps, distance, seconds, RPE) and creates corresponding records. After import, all historical workouts appear in History and contribute to Profile metrics. Exercises are matched to the internal exercise list (or created if new).

**Why this priority**: Required so the app launches with full history rather than starting from zero. A one-time operation but critical for adoption.

**Independent Test**: Import the `strong_workouts.csv` file, verify all 78+ workouts appear in History with correct data, verify Profile shows accurate count and chart.

**Acceptance Scenarios**:

1. **Given** I have a Strong CSV export, **When** I trigger the import, **Then** all workouts are created with correct dates, names, durations, exercises, sets, weights, reps, distances, and times.
2. **Given** the CSV contains exercises not yet in the exercise database, **When** the import runs, **Then** new exercises are created automatically and matched to future workouts using the same name.
3. **Given** the import completes, **When** I view History, **Then** all imported workouts appear in correct chronological order alongside any workouts recorded natively in Kiln.
4. **Given** the import contains workouts named "New Legs/full Body A" or "New Legs/full Body B", **When** the import completes, **Then** two workout templates are auto-created using the exercises and set counts from the most recent occurrence of each. Other workout names do not generate templates.

---

### Edge Cases

- **What happens when the user starts a second workout while one is already in progress?** The app MUST prevent starting a new workout; it presents the in-progress workout with an option to discard it first.
- **What happens when the app is force-quit during a set completion write?** The write MUST be atomic — either the set is fully saved or not at all. On relaunch, the workout is restored to the last fully-saved state.
- **What happens when the user changes weight/reps after completing a set?** The edit MUST overwrite the completed set's data immediately and persist.
- **What happens when the rest timer is running and the user completes the next set early?** The current timer MUST be cancelled and a new timer starts for the newly completed set.
- **What happens when the user taps the Workout tab while a workout is in progress?** The active workout view is shown (not the template selection).
- **What happens when the user navigates to History/Profile during a workout?** The workout continues (timers keep running, elapsed time keeps counting). Returning to the Workout tab shows the active workout.
- **What happens when the user discards an in-progress workout?** A confirmation dialog appears. If confirmed, the workout data is deleted. If the user has completed zero sets, no confirmation is needed.
- **What happens during CSV import if a row has invalid data?** The row is skipped and logged. The import continues with valid rows. A summary shows how many rows succeeded vs. failed.
- **What happens if an exercise in the CSV has no weight (bodyweight exercise)?** Weight is stored as 0. The UI displays "BW" or omits the weight field.
- **What happens if the device has no network connectivity?** All functionality works offline. No features depend on server availability for the MVP.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display three tabs in a bottom navigation bar: Workout, History, and Profile. The tab bar MUST remain visible at all times, including during an active workout.
- **FR-002**: The Workout tab MUST display workout templates as tappable cards in a grid layout, showing template name, exercise summary, and last-used date.
- **FR-003**: Tapping a template card MUST immediately start a workout and transition to the active workout view within the Workout tab.
- **FR-004**: The active workout view MUST display all exercises from the template, each with set rows showing set number, previous performance (weight x reps from the most recent workout containing that exercise, regardless of template), current weight, current reps, and a completion button. Pre-fill is per-set: set 1 shows set 1's previous data, set 2 shows set 2's, etc.
- **FR-005**: Tapping the completion button on a set MUST: (a) mark the set complete, (b) persist the set data immediately, and (c) start the rest timer.
- **FR-006**: The rest timer MUST count down visibly in the active workout view and fire an audio + haptic alert on completion, including when the app is backgrounded or the device is locked.
- **FR-007**: The rest timer default duration MUST be configurable per exercise (default: 90 seconds). Users MUST be able to adjust the timer duration during a workout.
- **FR-008**: Weight and rep values MUST be editable inline before or after a set is completed.
- **FR-009**: Users MUST be able to add exercises to an in-progress workout via a searchable exercise picker.
- **FR-010**: Users MUST be able to swap an exercise in an in-progress workout with a different exercise.
- **FR-011**: Users MUST be able to add or remove set rows for any exercise during a workout.
- **FR-012**: The "Finish Workout" action MUST save the complete workout record (timestamp, duration, all exercises with all set data) and return to the template selection.
- **FR-013**: If the app is terminated during an active workout, it MUST restore the workout on next launch with all previously completed sets intact.
- **FR-014**: The History tab MUST display a scrollable, chronological list of completed workouts (most recent first) with name, date, duration, total volume, and exercise summary.
- **FR-015**: Tapping a workout in History MUST show the full workout detail with all exercises and sets.
- **FR-016**: The Profile tab MUST display the user's name, photo, total workout count, and a workouts-per-week bar chart for the last 8 weeks.
- **FR-017**: Users MUST be able to create, edit, and delete workout templates.
- **FR-018**: The app MUST support importing workout history from Strong's CSV export format, mapping all fields (Date, Workout Name, Duration, Exercise Name, Set Order, Weight, Reps, Distance, Seconds, RPE) to internal records. The import MUST auto-create workout templates for "New Legs/full Body A" and "New Legs/full Body B" only, using the exercises and set counts from the most recent occurrence of each in the CSV.
- **FR-019**: All data MUST be stored locally on-device. No features in the MVP require network connectivity.
- **FR-020**: The app MUST support exercises that track weight + reps (strength), distance + time (cardio like rowing), or bodyweight + reps (no weight). The UI MUST adapt the set row display based on exercise type.
- **FR-021**: The "Start an Empty Workout" action MUST be available from the Workout tab, allowing users to begin a workout without a template and add exercises manually.

### Key Entities

- **Exercise**: A named movement (e.g., "Lat Pulldown (Cable)"). Has a type (strength, cardio, bodyweight) and optionally tracks weight, reps, distance, time, and RPE.
- **Workout Template**: A named collection of exercises with default set counts. Used as a starting point for workouts.
- **Workout**: A completed or in-progress training session. Has a start time, end time, duration, name (from template or custom), and an ordered list of workout exercises.
- **Workout Exercise**: An exercise performed within a specific workout. Has an order position within the workout and an ordered list of sets.
- **Set**: A single set within a workout exercise. Tracks set order, weight, reps, distance, seconds, RPE, and completion status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A workout can be started from a template in 1 tap from the Workout tab.
- **SC-002**: A set can be completed (pre-filled data, tap done) in 1 tap.
- **SC-003**: Rest timer alerts fire within 1 second of the target time, regardless of whether the app is in the foreground, background, or the device is locked.
- **SC-004**: After force-quitting during a workout with 10 completed sets, relaunching the app restores all 10 sets with zero data loss.
- **SC-005**: Importing 1,734 rows from Strong CSV completes without error and produces the correct number of workouts in History.
- **SC-006**: The workouts-per-week chart on Profile accurately reflects data from the last 8 weeks within 1 workout of the actual count.
- **SC-007**: All workout CRUD operations (complete set, add exercise, edit weight, finish workout) persist data within 100ms of user action — the user never waits for a save.
- **SC-008**: The bottom navigation bar is visible and functional on every screen, including during an active workout.

## Clarifications

### Session 2026-02-22

- Q: Should set pre-fill data come from the last time the exercise was performed in any workout (global) or only within the same template? → A: Global — pre-fill from the most recent workout containing that exercise, regardless of which template was used.
- Q: Should the CSV import auto-create workout templates from distinct workout names? → A: Auto-create only for "New Legs/full Body A" and "New Legs/full Body B" (current active routines). All other workout names are imported as history only, no template created.

### Assumptions

- The MVP operates entirely offline; server sync is deferred to a future feature.
- Profile name and photo are hardcoded or set once during initial setup — no editing UI needed for MVP.
- The exercise database is seeded from the Strong CSV import (exercise names are auto-created). A pre-populated exercise library is deferred.
- Rest timer default of 90 seconds is used unless the user adjusts it. Per-exercise customization of default rest time is in-scope for template editing.
- The Strong CSV import is triggered manually (e.g., via a share sheet or settings action). It does not need a polished onboarding flow for MVP.
- "Total volume" is calculated as the sum of (weight x reps) across all sets in a workout.
