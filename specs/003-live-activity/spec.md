# Feature Specification: Live Activity Lock Screen Workout

**Feature Branch**: `003-live-activity`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "This feature adds a live activity to the lock screen ONLY during an active workout. The goal is for a user to be able to complete their entire workout from the live activity."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete a Set from the Lock Screen (Priority: P1)

A user is at the gym with their phone locked in their pocket or on a bench. They glance at the lock screen and see their current exercise name, what they lifted last time (previous set), and the pre-filled weight and reps for the current set. They tap the +/- buttons to adjust the weight or reps if needed, then tap the "Complete" button to log the set. The rest timer immediately starts counting down on the lock screen. They can watch the timer without unlocking their phone.

**Why this priority**: This is the core value proposition — the user can log sets without ever unlocking their phone or navigating the app. Every gym session benefits from this.

**Independent Test**: Can be fully tested by starting a workout, locking the phone, completing a set via the lock screen, and verifying the set is recorded and the rest timer starts.

**Acceptance Scenarios**:

1. **Given** an active workout with an incomplete set, **When** the user views the lock screen, **Then** they see the current exercise name, previous set data, current weight, and current reps displayed clearly.
2. **Given** the lock screen shows an incomplete set, **When** the user taps the weight "+" button, **Then** the displayed weight increases by the standard increment (same as in-app: ±1 lb for weight, ±1 for reps).
3. **Given** the lock screen shows an incomplete set, **When** the user taps the "Complete" button, **Then** the set is marked as completed in the workout data and the rest timer begins counting down.
4. **Given** the lock screen shows an incomplete set with no previous workout data for that exercise, **When** the user views the lock screen, **Then** the previous set area shows a dash or "—" indicating no history.

---

### User Story 2 - Rest Timer on Lock Screen with Sound Alert (Priority: P1)

After completing a set, the user sees a countdown timer on the lock screen showing how much rest time remains. When the timer reaches zero, a sound plays to alert the user that rest is over. The lock screen then automatically transitions to show the next incomplete set — whether that's the next set of the same exercise or the first set of the next exercise.

**Why this priority**: The rest timer is tightly coupled with set completion — together they form the complete set-to-set workflow that enables hands-free workout tracking.

**Independent Test**: Can be tested by completing a set, verifying the timer appears and counts down, verifying the sound plays at zero, and verifying the next set is shown.

**Acceptance Scenarios**:

1. **Given** the user just completed a set, **When** the rest timer starts, **Then** the lock screen shows a countdown with the remaining time and a visual progress indicator.
2. **Given** the rest timer is counting down, **When** the timer reaches zero, **Then** an audible alert sound plays (even if the phone is locked) and the display transitions to the next incomplete set.
3. **Given** the rest timer is running, **When** there are still incomplete sets in the current exercise, **Then** after the timer expires the next incomplete set of the same exercise is shown.
4. **Given** the rest timer is running and all sets for the current exercise are complete, **When** the timer expires, **Then** the first incomplete set of the next exercise in the workout is shown.
5. **Given** the rest timer is running, **When** the user wants to skip rest early, **Then** the user can tap a skip/dismiss action to end the timer and immediately see the next set.

---

### User Story 3 - Live Activity Lifecycle (Priority: P2)

When the user starts a workout (from a template or as an empty workout), a live activity automatically appears on the lock screen showing the first incomplete set. The live activity persists throughout the entire workout session. When the user finishes or discards the workout (from the app), the live activity is removed from the lock screen.

**Why this priority**: The automatic lifecycle ensures the live activity is always present when needed and never lingers when not — a prerequisite for the core set-completion flow.

**Independent Test**: Can be tested by starting a workout and verifying the live activity appears, then finishing the workout and verifying it disappears.

**Acceptance Scenarios**:

1. **Given** no active workout, **When** the user starts a workout from a template, **Then** a live activity appears on the lock screen showing the first exercise and first set.
2. **Given** no active workout, **When** the user starts an empty workout, **Then** a live activity appears on the lock screen (showing workout name and elapsed time, with set details once exercises are added from the app).
3. **Given** an active workout with a live activity, **When** the user finishes the workout from the app, **Then** the live activity is removed from the lock screen.
4. **Given** an active workout with a live activity, **When** the user discards the workout from the app, **Then** the live activity is removed from the lock screen.
5. **Given** an active workout, **When** the app is force-quit or crashes, **Then** the live activity remains on the lock screen and resumes correctly when the app is reopened (crash recovery).

---

### User Story 4 - Workout Completion from Lock Screen (Priority: P2)

After the user completes the final set of the final exercise and the last rest timer expires, the lock screen shows a "Workout Complete" summary state indicating all sets are done. The user can then open the app to formally finish the workout.

**Why this priority**: Provides clear closure to the lock-screen workout flow and guides the user to finalize the session.

**Independent Test**: Can be tested by completing all sets via the lock screen and verifying the completion state appears.

**Acceptance Scenarios**:

1. **Given** only one incomplete set remains in the entire workout, **When** the user completes that set and the rest timer expires, **Then** the lock screen shows a completion state (e.g., workout name, total elapsed time, "All sets complete").
2. **Given** the lock screen is showing the completion state, **When** the user taps the live activity, **Then** the app opens to the active workout view where they can tap "Finish Workout."

---

### Edge Cases

- What happens when the user adjusts weight/reps via the lock screen and then also opens the app? The in-app view must reflect the changes made from the lock screen in real time.
- What happens when an exercise uses an equipment type without a weight field (e.g., reps-only, duration, distance)? The live activity adapts its display to show only the relevant fields for that equipment type, matching the in-app behavior.
- What happens if the user adds a new exercise or set from the app while the live activity is showing? The live activity updates to reflect the new workout state on the next state change.
- What happens if the rest timer expires while the phone is in Do Not Disturb or Silent mode? The existing notification behavior applies — background notifications are already configured for rest timer alerts.
- What happens on devices that do not support Live Activities (older iOS versions)? The feature is simply not available; the workout experience in-app remains unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a live activity on the lock screen when and only when a workout is in progress.
- **FR-002**: System MUST show the current exercise name on the lock screen when no rest timer is running.
- **FR-003**: System MUST show the previous set data (from the most recent prior workout containing the same exercise) on the lock screen, formatted consistently with the in-app "PREVIOUS" column (e.g., "55 lbs x 8").
- **FR-004**: System MUST show the current set's weight and reps values on the lock screen, pre-filled from the most recent prior workout data (same as in-app pre-fill behavior).
- **FR-005**: System MUST provide increment (+) and decrement (−) buttons for weight and reps on the lock screen, using the same step sizes as the in-app custom keyboard (±1 lb for weight, ±1 for reps).
- **FR-006**: System MUST provide a "Complete" action on the lock screen that marks the current set as completed and starts the rest timer.
- **FR-007**: System MUST display a countdown timer on the lock screen when a rest timer is active, showing remaining time and visual progress.
- **FR-008**: System MUST play an audible alert when the rest timer reaches zero, consistent with the existing background notification sound behavior.
- **FR-009**: System MUST automatically advance to the next incomplete set after the rest timer expires — prioritizing remaining sets in the current exercise, then moving to the next exercise's first incomplete set.
- **FR-010**: System MUST adapt the lock screen display to the current exercise's equipment type, showing only relevant input fields (e.g., reps only for bodyweight exercises, duration for timed exercises, distance for distance exercises).
- **FR-011**: System MUST start the live activity automatically when a workout begins (from template or empty workout) and end it when the workout is finished or discarded.
- **FR-012**: System MUST keep workout data synchronized between the lock screen live activity and the in-app views — changes made from either surface must be reflected in both.
- **FR-013**: System MUST display a completion state on the lock screen when all sets in the workout have been completed.
- **FR-014**: System MUST allow the user to skip the rest timer from the lock screen, immediately advancing to the next set.
- **FR-015**: System MUST show the workout elapsed time on the lock screen throughout the session.
- **FR-016**: System MUST survive app termination — if the app is killed while a workout is active, the live activity persists and resumes correctly when the app relaunches.

### Key Entities

- **Live Activity State**: Represents the current snapshot of data displayed on the lock screen — includes current exercise name, set number, weight, reps, previous set data, rest timer status, elapsed workout time, and whether the workout is complete.
- **Set Progression**: The ordered sequence of incomplete sets across all exercises in the workout, determining which set to show next after each completion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete an entire workout (all sets across all exercises) from the lock screen without unlocking their phone or opening the app.
- **SC-002**: The lock screen updates to show the next set within 1 second of the rest timer expiring.
- **SC-003**: Weight and reps adjustments made on the lock screen are immediately reflected when the user opens the app (and vice versa).
- **SC-004**: The rest timer countdown on the lock screen is accurate to within 1 second of the actual remaining time.
- **SC-005**: The audible alert plays within 1 second of the rest timer reaching zero.
- **SC-006**: The live activity appears on the lock screen within 2 seconds of starting a workout.
- **SC-007**: The live activity is removed from the lock screen within 2 seconds of finishing or discarding a workout.
- **SC-008**: 100% of equipment types supported in the app are correctly represented on the lock screen with appropriate input fields.

## Assumptions

- Target devices are iPhone 13 and iPhone 13 mini only. These devices do not have a Dynamic Island, so only the lock screen live activity widget is used — no Dynamic Island presentation is needed.
- Finishing and discarding a workout are done from within the app, not from the lock screen. The lock screen handles set completion and rest timer workflow only.
- The +/- increment steps for non-standard equipment types follow the same conventions as the in-app custom keyboard: ±5 seconds for duration, ±0.1 for distance.
- Adding exercises, adding sets, deleting sets, swapping exercises, and removing exercises are performed from within the app — the lock screen focuses exclusively on the set completion workflow.
- The rest timer duration uses the exercise's default rest time (currently 120 seconds), matching the in-app behavior.
- iOS 16.1+ is required for Live Activity support (iPhone 13 and 13 mini support this).
