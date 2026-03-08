# Feature Specification: Workout History Sync

**Feature Branch**: `008-workout-history-sync`
**Created**: 2026-03-08
**Status**: Draft
**Input**: User description: "Now that user profiles are implemented in the mongodb database, we should support syncing workout history. On the next connection with the server, the user's complete history should be saved to a table in a way that it is associated with that user. After that first sync, every time a workout is completed, it should be sent to the server to record it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initial Full History Sync (Priority: P1)

When a user opens the app and has a valid server connection, their complete local workout history is uploaded to the server for the first time. This creates a cloud backup of all historical data tied to their user account.

**Why this priority**: Without the initial bulk sync, no workout data exists on the server. This is the foundation — all other sync behavior depends on the server having a baseline copy of the user's history.

**Independent Test**: Can be tested by logging in with a valid API key on a device with existing local workout history and verifying all workouts appear in the server database under that user's account.

**Acceptance Scenarios**:

1. **Given** a user with 50 local workouts who has never synced, **When** the app connects to the server, **Then** all 50 workouts (with their exercises and sets) are uploaded and associated with the user's account.
2. **Given** a user whose history has already been synced, **When** the app connects to the server again, **Then** no duplicate workouts are created on the server.
3. **Given** a user with no local workouts, **When** the app connects to the server, **Then** no sync occurs and no errors are shown.
4. **Given** a user mid-sync who loses network connectivity, **When** connectivity is restored, **Then** the sync resumes or retries without creating duplicates.

---

### User Story 2 - Automatic Sync on Workout Completion (Priority: P1)

When a user finishes a workout, the completed workout is automatically sent to the server in the background. The user does not need to take any manual action — sync happens seamlessly after tapping "Finish."

**Why this priority**: This is the ongoing sync mechanism. After the initial bulk upload, each new workout must be recorded server-side to keep the cloud copy current.

**Independent Test**: Can be tested by completing a workout with the app connected to the server and verifying the workout appears in the server database within seconds.

**Acceptance Scenarios**:

1. **Given** a user who just finished a workout, **When** the celebration screen appears, **Then** the completed workout (with all exercises and sets) is sent to the server in the background.
2. **Given** a user who finishes a workout while offline, **When** connectivity is restored and the app is opened, **Then** the unsynced workout is uploaded to the server.
3. **Given** a workout sync that fails due to a server error, **When** the app is next opened with connectivity, **Then** the failed workout is retried.

---

### User Story 3 - Sync Status Visibility (Priority: P2)

The user can see whether their workout history is fully synced with the server. This provides confidence that their data is backed up.

**Why this priority**: While sync happens automatically, users need reassurance their data is safe. A simple indicator prevents anxiety about data loss.

**Independent Test**: Can be tested by checking the profile screen for a sync status indicator after completing a sync, and verifying it updates when workouts are pending upload.

**Acceptance Scenarios**:

1. **Given** all workouts are synced, **When** the user views their profile, **Then** they see an indication that their data is fully backed up.
2. **Given** there are unsynced workouts, **When** the user views their profile, **Then** they see how many workouts are pending sync.

---

### Edge Cases

- What happens when two devices sync the same workout history for the same user? Duplicates are prevented by matching on the workout's unique local identifier per user.
- What happens if a workout is deleted locally after being synced? Deletions are not synced in this version — the server retains a complete history.
- What happens if the server is unreachable for an extended period? Unsynced workouts queue locally and are uploaded when connectivity returns.
- What happens with workouts that were discarded (not completed)? Only completed workouts (with a completion timestamp) are synced.
- What happens if the initial bulk sync is interrupted partway through? Each workout is uploaded individually with deduplication, so a partial sync can safely resume from where it left off.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST upload all completed local workouts to the server on first sync, associated with the authenticated user's account.
- **FR-002**: System MUST automatically upload each newly completed workout to the server immediately after the user finishes it.
- **FR-003**: System MUST prevent duplicate workouts on the server by using the local workout identifier as a unique key per user.
- **FR-004**: System MUST persist sync state locally so it knows which workouts have been synced and which are pending.
- **FR-005**: System MUST retry failed uploads when connectivity is restored or the app is next opened.
- **FR-006**: System MUST store workouts on the server with the full hierarchy: workout metadata (name, start time, completion time, duration), exercises performed (with order and exercise reference), and individual sets (with weight, reps, distance, seconds, RPE).
- **FR-007**: System MUST store exercise definitions (name, body part, equipment type, exercise type) on the server as a reference collection, deduplicated by exercise name per user.
- **FR-008**: System MUST display sync status on the user's profile screen showing whether all data is backed up or how many workouts are pending.
- **FR-009**: System MUST only sync workouts that are completed — in-progress and discarded workouts are excluded.
- **FR-010**: System MUST perform sync operations in the background without blocking the user interface.

### Key Entities

- **Exercise (server)**: A unique exercise definition belonging to a user — name, body part, equipment type, exercise type. Referenced by workout records to avoid repeating exercise metadata in every workout. Deduplicated by exercise name within a user's scope.
- **Workout (server)**: A completed workout session belonging to a user — name, start time, completion time, duration in seconds. Contains an ordered list of exercises performed with their sets. Uniquely identified by the local workout identifier to prevent duplicates.
- **Workout Exercise (embedded)**: An exercise performed within a specific workout — its position order and reference to the exercise definition. Contains the sets performed.
- **Workout Set (embedded)**: An individual set within a workout exercise — position order, weight (lbs), reps, distance, seconds, RPE, and completion time. Mirrors the local data model fields.
- **Sync State (local-only)**: Tracks which local workouts have been successfully uploaded to the server. Enables the system to identify pending workouts and display sync status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user's complete workout history (up to 1,000 workouts) syncs to the server within 30 seconds on a typical mobile connection.
- **SC-002**: Newly completed workouts appear on the server within 5 seconds of the user tapping "Finish" when online.
- **SC-003**: No duplicate workouts exist on the server after multiple app launches, background/foreground cycles, or network interruptions.
- **SC-004**: Users can see their sync status (fully synced or N workouts pending) on their profile screen.
- **SC-005**: Workouts queued while offline are successfully uploaded within one app session after connectivity returns.

## Assumptions

- Only completed workouts are synced — templates, in-progress workouts, and discarded workouts are excluded from sync.
- Sync is one-directional (device → server) in this version. Restoring data from server to device is out of scope.
- Each user's exercise definitions are scoped to that user (not shared across users), matching the current local-first model.
- The existing per-user API key authentication (from feature 007) is used to identify and authorize sync requests.
- Workout identifiers generated locally are globally unique and safe to use as server-side deduplication keys.
- The server does not need to handle concurrent writes from multiple devices for the same user in this version (single-device per user).
- Deleted workouts on the device are not propagated to the server — the server maintains a complete append-only history.

## Out of Scope

- Server → device sync (restoring/downloading workout history to a new device)
- Syncing workout templates
- Syncing exercise deletions or edits retroactively
- Multi-device conflict resolution
- Data export from server
