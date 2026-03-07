# Feature Specification: Hybrid Rest Timer with Backend

**Feature Branch**: `006-hybrid-timer-backend`
**Created**: 2026-03-07
**Status**: Draft
**Input**: User description: "Hybrid approach: local notifications for reliable alerts + Coolify self-hosted backend with APNS push-to-update for Live Activity state transitions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Rest Timer Alert (Priority: P1)

As a user doing a workout, when I complete a set and a 2-minute rest timer starts, I must hear an alert sound and see a notification when the timer expires — regardless of whether the app is in the foreground, background, or the phone is locked.

**Why this priority**: This is the core problem. The current timer alert is unreliable because it depends on the app process staying alive. Users miss their rest intervals, disrupting their workout flow.

**Independent Test**: Complete a set, lock the phone, wait 2 minutes. Verify that a notification alert fires with sound exactly when the timer expires.

**Acceptance Scenarios**:

1. **Given** a rest timer is running and the app is in the foreground, **When** the timer reaches zero, **Then** an alert sound plays and a haptic fires
2. **Given** a rest timer is running and the app is backgrounded, **When** the timer reaches zero, **Then** a local notification appears with sound
3. **Given** a rest timer is running and the phone is locked, **When** the timer reaches zero, **Then** a local notification appears on the lock screen with sound
4. **Given** the user skips the rest timer before it expires, **When** skip is pressed, **Then** the pending local notification is cancelled and no alert fires
5. **Given** notification permission has not been granted, **When** the user starts their first workout, **Then** the app requests notification permission

---

### User Story 2 - Live Activity Transitions on Timer Expiry (Priority: P1)

As a user viewing the lock screen Live Activity during a rest period, when the rest timer reaches zero, the Live Activity must automatically transition from the timer countdown view to the next set view — without opening the app.

**Why this priority**: Equally critical to the alert. The Live Activity staying stuck on a "0:00" timer view is the other half of the reliability problem. Users cannot proceed to their next set from the lock screen without this transition.

**Independent Test**: Complete a set from the lock screen Live Activity, observe the timer countdown, wait for expiry. Verify the Live Activity switches to display the next set's weight/reps input.

**Acceptance Scenarios**:

1. **Given** the Live Activity is showing the timer countdown and the app is backgrounded, **When** the timer reaches zero, **Then** the Live Activity updates to show the next set view with correct exercise name, weight, and reps
2. **Given** the Live Activity is showing the timer countdown and the phone is locked, **When** the timer reaches zero, **Then** the Live Activity updates to show the next set view
3. **Given** the timer expires and the next set is in a different exercise, **When** the Live Activity transitions, **Then** the new exercise name, set number, and pre-filled values are displayed correctly
4. **Given** the timer expires and all sets are complete, **When** the Live Activity transitions, **Then** the completion view is shown
5. **Given** the backend server is unreachable when a timer starts, **When** the timer expires, **Then** the local notification alert still fires (graceful degradation), and the Live Activity updates when the app next returns to foreground

---

### User Story 3 - Backend Timer Scheduling (Priority: P2)

As the system, when a rest timer is started, the app sends the timer duration and Live Activity push token to the Coolify-hosted backend. The backend schedules an APNS push that fires at the exact expiry time to update the Live Activity.

**Why this priority**: This is the infrastructure that enables User Story 2. It's P2 because the alert (User Story 1) can work independently via local notifications, but the Live Activity transition requires this backend.

**Independent Test**: Start a rest timer, verify the backend receives the request, and after the duration elapses, verify an APNS push is sent that updates the Live Activity content state.

**Acceptance Scenarios**:

1. **Given** a set is completed and a rest timer starts, **When** the app has network connectivity, **Then** the app sends the push token, timer duration, and new content state to the backend
2. **Given** the backend receives a timer schedule request, **When** the specified duration elapses, **Then** the backend sends an APNS push with the correct content state payload to update the Live Activity
3. **Given** a rest timer is skipped before expiry, **When** the user taps skip, **Then** the app sends a cancellation request to the backend and no APNS push is sent
4. **Given** the backend receives a new timer request for the same device while one is pending, **When** the new request arrives, **Then** the previous pending timer is cancelled and replaced
5. **Given** the app has no network connectivity, **When** a set is completed, **Then** the rest timer and local notification still function normally (the Live Activity transition degrades to foreground-resume sync)

---

### User Story 4 - Remove Silent Audio Dependency (Priority: P3)

As a user, the app should no longer play silent audio in the background to keep the process alive. The background audio workaround is no longer needed because the timer alert is handled by local notifications and the Live Activity update is handled by APNS push.

**Why this priority**: Once the hybrid approach is working, the silent audio hack can be removed, reducing battery drain and eliminating the audio session side effects (interfering with other apps' audio, Now Playing widget artifacts).

**Independent Test**: Start a workout, complete a set, background the app, verify no silent audio is playing (check Control Center for Now Playing), confirm timer and Live Activity still work correctly.

**Acceptance Scenarios**:

1. **Given** a workout is in progress, **When** the app is backgrounded, **Then** no audio session is active unless the alert sound is playing
2. **Given** the silent audio dependency is removed, **When** the rest timer expires in the background, **Then** the local notification fires and the Live Activity updates via APNS push
3. **Given** the alert sound needs to play on timer expiry in the foreground, **When** the timer reaches zero, **Then** the alert sound plays without requiring a persistent background audio session

---

### Edge Cases

- What happens when the user force-quits the app while a timer is running? The local notification still fires (scheduled with iOS). The APNS push still fires (scheduled on backend). On next app launch, foreground resume syncs state.
- What happens when the Live Activity push token rotates mid-timer? The pending APNS push uses the token captured at timer start. If it fails due to token rotation, the Live Activity updates on foreground resume.
- What happens when the backend crashes or restarts during a pending timer? The scheduled timer is lost. The local notification still fires. The Live Activity updates on foreground resume (graceful degradation).
- What happens when multiple sets are completed rapidly from the lock screen? Each completion cancels the previous pending timer (both local notification and backend request) and schedules a new one.
- What happens when the workout is finished or discarded while a timer is running? All pending notifications are cancelled, the backend cancellation request is sent, and the Live Activity ends normally.
- What happens when the device is in Do Not Disturb or Focus mode? Local notifications may be silenced per user's Focus settings. The APNS Live Activity update still applies (Live Activities bypass Focus by default).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST schedule a local notification with sound when a rest timer starts, timed to fire at the exact expiry moment
- **FR-002**: System MUST cancel any pending local notification when the rest timer is skipped, a new timer starts, or the workout ends
- **FR-003**: System MUST request notification permission from the user before scheduling the first local notification
- **FR-004**: System MUST start the Live Activity with push-to-update capability to enable server-driven updates
- **FR-005**: System MUST observe the Live Activity push token and send it to the backend when a rest timer starts
- **FR-006**: Backend MUST accept a timer schedule request containing: push token, duration in seconds, and the content state payload for the next set
- **FR-007**: Backend MUST send a Live Activity update push with the content state payload after the specified duration elapses
- **FR-008**: Backend MUST authenticate with the Apple push notification service using the app's signing key
- **FR-009**: Backend MUST cancel a pending timer when it receives a cancellation request for the same device/token
- **FR-010**: System MUST continue to function for alerts (local notifications) when the backend is unreachable
- **FR-011**: System MUST remove the silent background audio mechanism
- **FR-012**: System MUST still play the alert tone sound in the foreground when the timer expires while the app is active
- **FR-013**: Backend MUST be deployable as a containerized service on Coolify

### Key Entities

- **Timer Schedule Request**: Push token, duration (seconds), content state payload for post-timer Live Activity update, device identifier for cancellation
- **Live Activity Update Payload**: Content state matching the app's Live Activity data schema, delivered as a push-driven update
- **Local Notification**: Time-interval triggered notification with title ("Rest Complete"), body ("Time for your next set!"), and alert sound

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Rest timer alert fires within 1 second of the scheduled expiry time in 99%+ of cases, regardless of app state (foreground, background, locked, force-quit)
- **SC-002**: Live Activity transitions from timer view to next set view within 3 seconds of timer expiry in 95%+ of cases when the backend is reachable
- **SC-003**: When the backend is unreachable, the alert notification still fires reliably and the Live Activity recovers on next foreground resume
- **SC-004**: Battery impact is reduced compared to the current silent audio approach (no persistent background audio session)
- **SC-005**: End-to-end latency from timer expiry to Live Activity update is under 5 seconds

## Assumptions

- The Coolify instance is already provisioned and accessible for deploying containerized services
- An Apple Developer account with access to APNS authentication keys (p8) is available
- The app's bundle ID is registered for push notifications in the Apple Developer portal
- The backend will be a lightweight stateless service (no database required — timers held in memory with scheduled tasks)
- Network connectivity is available in most gym environments (WiFi or cellular)
- iOS guarantees local notification delivery even when the app is suspended or force-quit
- ActivityKit push-to-update is supported on iOS 16.1+ (the app targets iOS 17+, so this is covered)
