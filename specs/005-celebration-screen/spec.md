# Feature Specification: Celebration Screen

**Feature Branch**: `005-celebration-screen`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "When a user completes a workout, there should be a celebration screen with an encouraging animation, this is your xth workout, and the time & pounds total you lifted (also distance & reps & sets as needed). And whatever else we want to show"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Workout Completion Celebration (Priority: P1)

As a user who just finished a workout, I want to see a celebratory screen that congratulates me and shows a summary of what I accomplished, so I feel rewarded and motivated to keep working out.

After tapping "Finish" (or "Finish & Update Template") on the end-workout overlay, instead of immediately returning to the template grid, the user sees a full-screen celebration with an encouraging animation, their total workout number ("This is your 47th workout!"), and key stats from the session.

**Why this priority**: This is the core feature — the celebration moment with stats is the entire value proposition. Without it, there's nothing.

**Independent Test**: Can be fully tested by completing any workout and verifying the celebration screen appears with the correct stats and animation.

**Acceptance Scenarios**:

1. **Given** a user has an active workout with completed sets, **When** they tap "Finish" on the end-workout overlay, **Then** a full-screen celebration view appears with an encouraging animation, their total workout count ordinal (e.g., "47th workout"), and workout summary stats.
2. **Given** a user has an active workout with completed sets, **When** they tap "Finish & Update Template", **Then** the same celebration screen appears (template update happens silently in the background).
3. **Given** the celebration screen is displayed, **When** the user taps a dismiss action (button or gesture), **Then** the app returns to the template grid (start workout view).

---

### User Story 2 - Adaptive Stats Display (Priority: P2)

As a user, I want the celebration screen to show the stats that are relevant to my workout type, so the summary feels personalized and meaningful rather than showing zeros for irrelevant metrics.

The stats displayed should adapt based on the exercises performed. A strength-focused workout shows total weight lifted and sets/reps. A cardio workout shows distance and duration. A mixed workout shows all relevant metrics.

**Why this priority**: Showing irrelevant stats (e.g., "0 lbs lifted" for a bodyweight workout, or "0 miles" for a bench press session) would undermine the celebration feeling. Adaptive display is essential for the feature to feel polished.

**Independent Test**: Can be tested by completing workouts of different types (strength-only, cardio-only, mixed) and verifying only relevant stats appear.

**Acceptance Scenarios**:

1. **Given** a workout contains only weight-based exercises (e.g., barbell, dumbbell), **When** the celebration screen displays, **Then** it shows total weight lifted (in lbs), total sets, and total reps — but does NOT show distance.
2. **Given** a workout contains only bodyweight/reps-only exercises, **When** the celebration screen displays, **Then** it shows total sets and total reps — but does NOT show total weight lifted or distance.
3. **Given** a workout contains distance-based exercises (e.g., treadmill, cycling), **When** the celebration screen displays, **Then** it shows total distance — but does NOT show total weight lifted.
4. **Given** a workout contains a mix of exercise types, **When** the celebration screen displays, **Then** it shows all metrics that have non-zero values.
5. **Given** any workout, **When** the celebration screen displays, **Then** it always shows workout duration and total workout count regardless of exercise type.

---

### User Story 3 - Personal Record Highlights (Priority: P3)

As a user, I want to see if I set any personal records during this workout, so I get an extra dopamine hit for my achievement.

If the user lifted more weight on a particular exercise than they ever have before (highest single-set volume: weight x reps), the celebration screen highlights that exercise as a new personal record.

**Why this priority**: Personal records add a powerful motivational layer on top of the base celebration. However, the celebration screen delivers value without them, so they can be added as an enhancement.

**Independent Test**: Can be tested by completing a workout where one exercise exceeds the user's historical best single-set volume, and verifying the PR is highlighted on the celebration screen.

**Acceptance Scenarios**:

1. **Given** a user completes a set with higher volume (weight x reps) than any previous set for that exercise across all past workouts, **When** the celebration screen displays, **Then** that exercise is highlighted as a personal record with the new best shown.
2. **Given** a user completes a workout with no personal records, **When** the celebration screen displays, **Then** no personal record section appears (it is omitted, not shown empty).
3. **Given** a user sets multiple personal records in one workout, **When** the celebration screen displays, **Then** all personal records are listed.

---

### Edge Cases

- What happens when the user completes a workout with zero completed sets (all sets left incomplete)? The celebration screen should still appear but show "0" for stats where applicable, with duration still displayed.
- What happens on the user's very first workout ever? The workout count should display as "1st workout" with correct ordinal formatting.
- What happens if the workout has only duration-based exercises (e.g., planks) with no weight, reps, or distance? Only duration-related stats and total sets are shown.
- What happens if the app is backgrounded while the celebration screen is visible? The celebration screen should persist and still be visible when the user returns.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a full-screen celebration view after the user taps "Finish" or "Finish & Update Template" on the end-workout overlay.
- **FR-002**: The celebration screen MUST show the user's total completed workout count as an ordinal number (e.g., "1st", "2nd", "3rd", "47th") in a prominent encouraging message.
- **FR-003**: The celebration screen MUST include an encouraging visual animation that plays automatically on appearance.
- **FR-004**: The celebration screen MUST display workout duration in a human-readable format (e.g., "1h 23m" or "45m").
- **FR-005**: The celebration screen MUST display total weight lifted (in lbs) when the workout includes any weight-based exercises.
- **FR-006**: The celebration screen MUST display total sets completed and total reps performed when relevant exercises are present.
- **FR-007**: The celebration screen MUST display total distance when the workout includes any distance-based exercises.
- **FR-008**: The celebration screen MUST NOT display metrics that have zero values or are not applicable to the exercises performed (except duration and workout count, which always display).
- **FR-009**: The celebration screen MUST provide a clear way for the user to dismiss it and return to the start workout (template grid) view.
- **FR-010**: The celebration screen MUST highlight any personal records set during the workout (P3 — may be deferred).
- **FR-011**: The celebration screen MUST fit the app's existing fire/warm visual theme.

### Key Entities

- **Workout Summary**: Aggregated stats for a single completed workout — duration, total volume, total sets, total reps, total distance, exercise count. Computed from existing Workout, WorkoutExercise, and WorkoutSet models at completion time.
- **Workout Count**: The ordinal position of this workout among all completed workouts. Derived by counting all completed (non-in-progress) workouts at the time of finishing.
- **Personal Record**: A new highest single-set volume (weight x reps) for a given exercise, compared against all historical completed workouts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of completed workouts (via "Finish" or "Finish & Update Template") trigger the celebration screen with correct stats.
- **SC-002**: The celebration screen displays within 1 second of the user tapping finish.
- **SC-003**: All displayed stats (weight, reps, sets, distance, duration, workout count) are accurate to the workout data.
- **SC-004**: The celebration screen correctly adapts its displayed metrics based on the exercise types in the workout — no zero-value or irrelevant stats are shown.
- **SC-005**: Users can dismiss the celebration screen and return to the template grid in a single action.
