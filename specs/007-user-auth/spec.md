# Feature Specification: User Authentication & Profiles

**Feature Branch**: `007-user-auth`
**Created**: 2026-03-08
**Status**: Draft
**Input**: User description: "Add API key-based auth for 2 sideloaded users (developer + wife). MongoDB backend for flexible schema. Login splash screen following Kiln's fire light theme. Keychain storage for API key. User profile display. Phase 1 — no workout sync yet."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First Launch API Key Entry (Priority: P1)

As a user opening Kiln for the first time (or after logging out), I see a branded login screen that matches Kiln's fire light aesthetic. I paste my API key into a text field, tap "Connect," and the app verifies my key against the backend. If valid, I'm taken to the main app. If invalid, I see a clear error message.

**Why this priority**: Without authentication, no other user-specific features can work. This is the gateway to multi-user support.

**Independent Test**: Launch the app with no stored credentials. Paste a valid API key, tap Connect, verify the app transitions to the main tab view. Repeat with an invalid key and verify an error is shown.

**Acceptance Scenarios**:

1. **Given** no API key is stored on the device, **When** the app launches, **Then** the login screen is displayed instead of the main tab view
2. **Given** the login screen is displayed, **When** the user pastes a valid API key and taps Connect, **Then** the backend validates the key, the key is stored securely on-device, and the app transitions to the main tab view
3. **Given** the login screen is displayed, **When** the user enters an invalid API key and taps Connect, **Then** an error message is displayed (e.g., "Invalid API key") and the user remains on the login screen
4. **Given** the login screen is displayed, **When** the user taps Connect with an empty field, **Then** the Connect button is disabled or an inline validation message appears
5. **Given** the login screen is displayed and the backend is unreachable, **When** the user taps Connect, **Then** a connection error message is shown (e.g., "Could not reach server. Check your connection.")

---

### User Story 2 - Persistent Authentication Across Launches (Priority: P1)

As an authenticated user, when I close and reopen the app, I should go directly to the main tab view without re-entering my API key. The stored credential persists across app restarts and device reboots.

**Why this priority**: Equally critical to the login flow — if the key isn't persisted securely, users would need to re-authenticate every session, which is unusable.

**Independent Test**: Log in successfully, force-quit the app, relaunch. Verify the main tab view appears immediately without the login screen.

**Acceptance Scenarios**:

1. **Given** a valid API key is stored on-device, **When** the app launches, **Then** the main tab view is shown directly (no login screen)
2. **Given** a valid API key is stored on-device, **When** the app launches with network connectivity, **Then** the app silently verifies the key in the background and fetches the user profile
3. **Given** a valid API key is stored on-device but the backend is unreachable, **When** the app launches, **Then** the app proceeds to the main tab view using cached user data (offline-tolerant)
4. **Given** a previously valid API key has been revoked server-side, **When** the app launches and the backend returns unauthorized, **Then** the stored key is cleared and the user is returned to the login screen

---

### User Story 3 - User Profile Display (Priority: P2)

As an authenticated user, I can see my name displayed in the Profile tab, confirming who I'm logged in as.

**Why this priority**: Provides identity confirmation and lays groundwork for future per-user features. Not blocking for core app usage.

**Independent Test**: Log in, navigate to Profile tab, verify the user's name (fetched from the backend) is displayed.

**Acceptance Scenarios**:

1. **Given** the user is authenticated, **When** they navigate to the Profile tab, **Then** their name (from the backend) is displayed
2. **Given** the user is authenticated but the backend is unreachable, **When** they navigate to the Profile tab, **Then** a cached version of their name is shown
3. **Given** the user's name is updated on the backend, **When** the app fetches the profile, **Then** the displayed name reflects the update

---

### User Story 4 - Logout (Priority: P3)

As a user, I can log out from the Profile tab to clear my stored credentials and return to the login screen. This allows switching between users on a shared device or re-authenticating with a different key.

**Why this priority**: Important for account management but not blocking for day-to-day usage with 2 dedicated devices.

**Independent Test**: While authenticated, tap Logout in Profile tab. Verify the login screen appears and the stored API key is cleared.

**Acceptance Scenarios**:

1. **Given** the user is authenticated and viewing the Profile tab, **When** they tap Logout, **Then** a confirmation prompt appears
2. **Given** the user confirms logout, **When** the action completes, **Then** the stored API key is removed from the device and the login screen is displayed
3. **Given** the user cancels the logout confirmation, **When** they dismiss the prompt, **Then** they remain on the Profile tab with no changes
4. **Given** a workout is in progress when the user attempts to log out, **When** they tap Logout, **Then** they are warned that the active workout will be lost, and must confirm before proceeding

---

### Edge Cases

- What happens when the user pastes a key with leading/trailing whitespace? The system trims whitespace before validation.
- What happens if the device has no internet on first launch? The login screen shows an appropriate error when Connect is tapped, since key validation requires the backend.
- What happens if the API key format is changed on the backend? The app treats any non-empty string as a potential key and relies on backend validation — no client-side format enforcement.
- What happens if the iOS Keychain is inaccessible (e.g., device locked with data protection)? The app falls back gracefully — showing the login screen if the key cannot be retrieved, rather than crashing.
- What happens if two users share one device? Logout clears all stored credentials and cached profile data, allowing a clean login as a different user.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a login screen when no valid API key is stored on-device
- **FR-002**: System MUST validate API keys against the backend before granting access to the main app
- **FR-003**: System MUST store the validated API key in the device's secure credential store (not in plain-text storage)
- **FR-004**: System MUST persist authentication across app restarts and device reboots
- **FR-005**: System MUST display an error message when an invalid API key is submitted
- **FR-006**: System MUST display a connection error when the backend is unreachable during login
- **FR-007**: System MUST allow authenticated users to proceed offline using cached profile data after initial validation
- **FR-008**: System MUST fetch and display the user's profile name in the Profile tab
- **FR-009**: System MUST cache the user's profile data locally for offline display
- **FR-010**: System MUST provide a logout option that clears stored credentials and cached data, returning the user to the login screen
- **FR-011**: System MUST show a confirmation prompt before logging out
- **FR-012**: System MUST warn the user if logging out during an active workout
- **FR-013**: Backend MUST store user profiles in a document-based database with flexible schema
- **FR-014**: Backend MUST authenticate requests using API keys passed in the Authorization header
- **FR-015**: Backend MUST provide an endpoint to verify an API key and return the associated user profile
- **FR-016**: Backend MUST come pre-seeded with 2 user accounts (no signup flow)
- **FR-017**: Login screen MUST follow the app's existing visual design language (warm cream background, fire red accent, grain texture)
- **FR-018**: Existing timer backend endpoints MUST continue to function with the new authentication layer

### Key Entities

- **User Profile**: Represents an app user. Contains name, API key, and creation timestamp. Stored on the backend in a document database. Cached locally on-device for offline access.
- **API Key**: A unique, randomly generated credential assigned to each user. Used as a Bearer token for all backend requests. Stored securely on-device after successful validation.
- **Auth Session**: The local state representing an authenticated user — consisting of a stored API key and cached profile data. Cleared on logout.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can authenticate by pasting their API key and tapping Connect in under 10 seconds
- **SC-002**: Authentication persists across 100% of app restarts — users never re-enter their key unless they explicitly log out or the key is revoked
- **SC-003**: Login screen visually matches Kiln's fire light design language (warm tones, grain texture, branded appearance)
- **SC-004**: Invalid API key attempts show clear feedback within 3 seconds
- **SC-005**: The app remains fully usable offline after initial authentication (all existing local features continue to work)
- **SC-006**: Existing timer backend functionality (timer scheduling, APNS push) is unaffected by the addition of user authentication
- **SC-007**: Logout fully clears credentials — re-launching after logout always shows the login screen

## Assumptions

- The Coolify instance can host a MongoDB service alongside the existing FastAPI backend
- Only 2 users will exist — no self-registration or admin panel is needed
- API keys are generated and distributed out-of-band (e.g., developer texts the key to wife)
- The API key format is a sufficiently long random string (32+ characters) for security against brute force
- The existing single API key in `Secrets.xcconfig` (used for timer backend auth) will be replaced by per-user API keys
- All existing app functionality (workouts, templates, history, rest timer, Live Activity) continues to work with local SwiftData — this feature adds authentication infrastructure only, no data sync
- User profile data is minimal (name only for now) but the document-based backend schema allows adding fields later without migrations
- Rate limiting on the login endpoint is not required for 2 users but may be added later as a security hardening measure
