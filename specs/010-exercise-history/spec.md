# Feature Specification: Exercise History Browser

**Feature Branch**: `010-exercise-history`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "A new Exercises tab that shows all exercises in alphabetical order that have been added by that user, and clicking on that exercise shows you all past times you have completed it (similar to the workout history view, when you tap on a workout to see the details of the sets you completed)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse All Exercises (Priority: P1)

As a user, I want to see a dedicated "Exercises" tab in the main tab bar that lists every exercise I've ever performed or created, sorted alphabetically. This gives me a quick reference of my full exercise library without needing to start a workout.

**Why this priority**: The exercise list is the foundation of the entire feature — without it, there's nothing to tap into for history.

**Independent Test**: Can be fully tested by opening the Exercises tab and verifying all user exercises appear in alphabetical order. Delivers value as a personal exercise catalog.

**Acceptance Scenarios**:

1. **Given** a user has completed workouts containing various exercises, **When** they tap the Exercises tab, **Then** they see every distinct exercise listed in alphabetical order (A→Z)
2. **Given** a user has no exercises (fresh install, no imports), **When** they tap the Exercises tab, **Then** they see an empty state message encouraging them to complete a workout first
3. **Given** a user has exercises with different equipment types, **When** they view the exercise list, **Then** each exercise row shows the exercise name and its equipment type (e.g., "Barbell", "Dumbbell")
4. **Given** the exercise list is long, **When** the user types in the search bar, **Then** the list filters to show only exercises matching the search text (case-insensitive)

---

### User Story 2 - View Exercise History (Priority: P1)

As a user, I want to tap on any exercise in the list and see every past workout session where I performed that exercise, with the specific sets, weights, and reps I completed. This lets me track my progress on individual exercises over time.

**Why this priority**: Viewing per-exercise history is the core value proposition — it's the reason to have the Exercises tab at all.

**Independent Test**: Can be tested by tapping an exercise and verifying all past performances appear with correct set details, ordered by most recent first.

**Acceptance Scenarios**:

1. **Given** a user taps on an exercise they've performed multiple times, **When** the exercise detail view loads, **Then** they see a list of past workout sessions containing that exercise, ordered by most recent first
2. **Given** a past workout session is shown, **When** the user views it, **Then** they see the date of the workout and each set completed (set number, weight, reps — or appropriate fields based on equipment type)
3. **Given** a user taps on an exercise they've only performed once, **When** the exercise detail view loads, **Then** they see that single workout session with all its sets
4. **Given** a user taps on an exercise they've never performed (only created), **When** the exercise detail view loads, **Then** they see an empty state message indicating no history yet

---

### User Story 3 - Search Exercises (Priority: P2)

As a user, I want to quickly search for a specific exercise by name so I can jump directly to its history without scrolling through the full list.

**Why this priority**: Search is a usability enhancement — important for users with many exercises, but the feature is usable without it via scrolling.

**Independent Test**: Can be tested by typing a search query and verifying the list filters correctly.

**Acceptance Scenarios**:

1. **Given** the user is on the Exercises tab, **When** they pull down to reveal the search bar and type a partial exercise name, **Then** only matching exercises are shown
2. **Given** the user searches for a term with no matches, **When** the results are empty, **Then** a "No exercises found" message is displayed

---

### Edge Cases

- What happens when an exercise was added to a workout but has zero completed sets? It should not appear in that exercise's history for that workout session.
- What happens when the same exercise name exists with different equipment types? Each Exercise is a unique entity by its persistent ID, so they appear as separate entries in the list.
- What happens when the user edits a past workout to change sets? The exercise history reflects the current saved state of all workouts (including edits).
- What happens when a workout is deleted? The exercise history no longer includes sets from that deleted workout.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a new "Exercises" tab in the main tab bar
- **FR-002**: The Exercises tab MUST list all exercises from the user's local data store, sorted alphabetically by name (A→Z)
- **FR-003**: Each exercise row MUST show the exercise name and equipment type
- **FR-004**: The Exercises tab MUST include a searchable list that filters exercises by name (case-insensitive)
- **FR-005**: Tapping an exercise MUST navigate to an exercise detail/history view
- **FR-006**: The exercise detail view MUST show all past workout sessions where the exercise was performed, ordered by most recent date first
- **FR-007**: Each workout session entry MUST display the workout date and all completed sets for that exercise (with set number and appropriate metrics based on equipment type: weight/reps, reps only, duration, or distance)
- **FR-008**: The exercise detail view MUST show an empty state when the exercise has no completed workout history
- **FR-009**: The Exercises tab MUST show an empty state when no exercises exist
- **FR-010**: Only sets that were marked as completed MUST appear in the exercise history

### Key Entities

- **Exercise**: The exercise definition (name, equipment type, body part). Already exists in the data model. Serves as the key for grouping history.
- **Workout Session (per-exercise)**: A grouping of completed sets for a specific exercise within a specific past workout. Displayed as a card showing the workout date and set details.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can find any exercise in their library within 5 seconds (via scrolling or search)
- **SC-002**: Users can view the full history of any exercise in 2 taps from the main screen (tap Exercises tab, then tap exercise)
- **SC-003**: Exercise history displays all past performances with no missing data (100% of completed sets are shown)
- **SC-004**: The exercise list loads and displays within 1 second of tapping the tab

## Assumptions

- The Exercises tab will be added as a 4th tab in the existing tab bar, positioned between History and Profile
- Body part icons (already in the asset catalog) may be shown in the exercise list rows for visual distinction, but this is an optional enhancement
- The exercise history view follows the same visual design language as the existing workout detail view (cards, fire light theme, grain texture)
- No server-side changes are needed — this feature reads entirely from local SwiftData
