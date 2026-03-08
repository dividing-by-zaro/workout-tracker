# Feature Specification: Workout Sync Updates

**Feature Branch**: `009-workout-sync-updates`
**Created**: 2026-03-08
**Status**: Draft
**Input**: User description: "when a workout is edited or deleted in the history view, that corresponding workout should be updated on the server as well"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edited Workout Syncs to Server (Priority: P1)

As a user, when I edit a completed workout in the history view (changing sets, exercises, or workout name), those changes should be reflected on the server so that the server backup stays accurate.

**Why this priority**: The server backup is only useful if it reflects the actual state of the user's data. Edits are the most common history mutation — users frequently fix typos, correct weights, or adjust sets after a workout.

**Independent Test**: Edit a previously synced workout's name or set data, then verify the server record matches the updated local data.

**Acceptance Scenarios**:

1. **Given** a completed workout that has already been synced to the server, **When** the user edits the workout name in the edit view, **Then** the updated workout is sent to the server and the server record reflects the new name.
2. **Given** a completed workout that has already been synced, **When** the user adds, removes, or swaps an exercise, **Then** the server record is updated with the new exercise list.
3. **Given** a completed workout that has already been synced, **When** the user toggles a set's completion status or changes set data (weight, reps, etc.), **Then** the server record is updated with the modified set data.
4. **Given** a completed workout that has NOT yet been synced, **When** the user edits the workout, **Then** the next sync uploads the edited version (no separate update needed).

---

### User Story 2 - Deleted Workout Removed from Server (Priority: P1)

As a user, when I delete a completed workout from the history view, that workout should also be removed from the server so the backup doesn't contain workouts I've intentionally discarded.

**Why this priority**: Equally critical as edits — if a user deletes a workout (e.g., an accidental or test workout), the server backup should not retain stale data that contradicts the user's intent.

**Independent Test**: Delete a previously synced workout from the history view, then verify the server no longer contains that workout record.

**Acceptance Scenarios**:

1. **Given** a completed workout that has been synced to the server, **When** the user deletes it via the history view confirmation dialog, **Then** the server record for that workout is removed.
2. **Given** a completed workout that has been synced, **When** the user deletes it while offline, **Then** the deletion is queued and sent to the server when connectivity is restored.
3. **Given** a completed workout that has NOT been synced, **When** the user deletes it, **Then** no server request is needed and the workout is simply removed locally.

---

### User Story 3 - Sync Resilience for Edits and Deletes (Priority: P2)

As a user, I want edit and delete syncs to be resilient to network failures so that my server backup eventually becomes consistent with my device, even if I'm temporarily offline.

**Why this priority**: Without retry logic, edits and deletes could silently fail, leaving the server backup in an inconsistent state. This is lower priority because the data is still correct locally.

**Independent Test**: Edit or delete a workout while in airplane mode, then restore connectivity and verify the change reaches the server.

**Acceptance Scenarios**:

1. **Given** a workout edit or delete fails due to a network error, **When** the app next launches or enters the foreground, **Then** the pending edit or delete is retried.
2. **Given** multiple edits are made to the same workout before sync succeeds, **When** the sync finally runs, **Then** only the latest state is sent (not intermediate edits).

---

### Edge Cases

- What happens when a workout is edited multiple times before the edit syncs? Only the latest state should be sent.
- What happens when a workout is edited and then deleted before either syncs? The delete takes precedence — only the delete needs to sync.
- What happens when the server returns an error for an update or delete? The operation should be queued for retry on next sync cycle.
- What happens when a workout that was never synced is deleted? No server action needed; just clean up the local sync tracking state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST send updated workout data to the server when a user finishes editing a previously synced workout in the history view.
- **FR-002**: System MUST send a delete request to the server when a user deletes a previously synced workout from the history view.
- **FR-003**: System MUST track pending edits and deletes separately from initial sync state, so that failed operations can be retried.
- **FR-004**: System MUST deduplicate pending operations — if a workout is edited multiple times before sync, only the final state is sent; if a workout is edited then deleted, only the delete is sent.
- **FR-005**: System MUST retry failed edit and delete operations on the next app launch or foreground resume.
- **FR-006**: System MUST NOT send edit or delete requests for workouts that have never been synced to the server.
- **FR-007**: When a previously synced workout is deleted locally, the system MUST remove it from the local synced workout tracking so it is not counted in sync status.

### Key Entities

- **Pending Edit**: A record indicating a synced workout has been modified locally and needs to be re-uploaded to the server. Identified by the workout's local ID.
- **Pending Delete**: A record indicating a synced workout has been deleted locally and needs to be removed from the server. Identified by the workout's local ID.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a user edits a synced workout and has network connectivity, the server record reflects the changes within 10 seconds of the user dismissing the edit view.
- **SC-002**: When a user deletes a synced workout and has network connectivity, the server record is removed within 10 seconds of the user confirming deletion.
- **SC-003**: Pending edits and deletes that fail due to network issues are successfully retried on the next app session, achieving eventual consistency between device and server.
- **SC-004**: The sync status displayed on the profile screen accurately reflects the count of workouts backed up on the server, accounting for deletions.

## Assumptions

- The server is the backup, not the source of truth — local SwiftData remains authoritative.
- Edits are sent as full workout replacements (upsert), not partial patches, keeping the approach simple and consistent with the existing upload payload structure.
- Deletes are permanent on the server (hard delete), matching the local behavior.
- The two-user household means no conflict resolution is needed — each user only edits their own workouts.
- Network retry uses the existing sync-on-launch pattern rather than introducing background task scheduling.
