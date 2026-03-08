<!--
  Sync Impact Report
  ===========================================================================
  Version change: 1.0.1 → 1.1.0

  Modified principles:
    - VI. Single-User Simplicity → Household Simplicity: expanded from
      1 user to 2 users (developer + wife). Per-user API keys, user
      profiles in MongoDB. No RBAC, no signup, no general multi-tenancy.

  Modified sections:
    - None (Technology Stack unchanged — MongoDB addition documented
      in CLAUDE.md, not constitution)

  Templates requiring updates:
    - .specify/templates/plan-template.md          ✅ no changes needed
    - .specify/templates/spec-template.md           ✅ no changes needed
    - .specify/templates/tasks-template.md          ✅ no changes needed
    - .specify/templates/agent-file-template.md     ✅ no changes needed
    - .specify/templates/checklist-template.md      ✅ no changes needed

  Follow-up TODOs: none
  ===========================================================================
-->

# Kiln Constitution

## Core Principles

### I. Zero Data Loss (NON-NEGOTIABLE)

Workout data MUST never be lost under any circumstance. This is the single
most critical property of the application.

- Every set completion MUST be persisted immediately (write-through, not
  batched) to local storage before any UI confirmation is shown.
- The app MUST survive force-quit, crash, backgrounding, low memory
  termination, and device restart without losing any recorded data.
- Local-first storage (Core Data or SwiftData) is the source of truth;
  server sync is secondary and MUST NOT gate the recording of data.
- Incomplete workouts MUST be recoverable on next app launch with all
  previously recorded sets intact.
- Sync failures MUST queue locally and retry automatically; the user MUST
  never need to manually re-enter data due to a network issue.

### II. Minimal Friction

Starting and progressing through a workout MUST require the fewest taps
possible. Speed of interaction is a core product value.

- Starting a workout from a template MUST be achievable in one tap from
  the home screen (Workout tab).
- Completing a set MUST be achievable in one tap during an active workout.
- Adding or swapping exercises during a workout MUST require no more than
  two taps (one to open picker, one to select).
- Previous set data (weight, reps) MUST be pre-filled from the most recent
  matching workout so the user only taps "done" in the common case.
- The active workout view MUST replace the Workout tab content entirely
  (no modals, no navigation push) while preserving the bottom tab bar for
  Profile/History access.

### III. Timer Reliability (NON-NEGOTIABLE)

Rest timers MUST always fire at the correct time regardless of app state.

- Timers MUST use background execution (BGTaskScheduler or UNNotification
  scheduling) so they fire even when the app is backgrounded or the device
  is locked.
- Timer state MUST be persisted so that if the app is terminated during a
  rest period, the timer resumes correctly on relaunch.
- Audio/haptic notification MUST fire at timer completion even if the app
  is not in the foreground.
- The Live Activity MUST show a real-time countdown of the rest timer on
  the lock screen.

### IV. Live Activity First

The lock screen Live Activity is a primary interaction surface, not a
secondary display. The target device is iPhone 13 (no Dynamic Island),
so the Live Activity presents as a large lock screen banner only.

- During an active workout, a Live Activity MUST be started and kept
  updated with the current exercise, set number, target reps, and weight.
- The Live Activity MUST use the expanded lock screen presentation; there
  is no need to design for compact or minimal Dynamic Island layouts.
- Users MUST be able to complete the current set directly from the Live
  Activity, which MUST immediately start the rest timer.
- The rest timer countdown MUST be displayed in real-time on the Live
  Activity using ActivityKit's countdown content state.
- When all sets for all exercises are complete, the Live Activity SHOULD
  offer a "Finish Workout" action.
- Live Activity state MUST stay in sync with the in-app workout state;
  any action taken from either surface MUST be immediately reflected in
  the other.

### V. Beautiful & Joyful Design

The app MUST have a clean, modern, and visually delightful interface that
is a clear upgrade over Strong.

- UI MUST be built with SwiftUI using native iOS design patterns (no
  custom chrome that fights the platform).
- Typography, spacing, and color MUST follow a consistent design system
  defined once and referenced throughout.
- Charts and graphs (workouts/week, exercise progression) MUST use Swift
  Charts for native, performant rendering.
- Animations MUST be purposeful and subtle (e.g., set completion
  confirmation, timer transitions) — never gratuitous.
- The interface MUST remain uncluttered; information density is controlled
  by progressive disclosure rather than cramming.

### VI. Household Simplicity

This is custom software for a household of two users (developer + wife).
All architecture decisions MUST reflect this constraint — no general
multi-tenancy, no user management UI, no signup flows.

- Authentication MUST use per-user API keys stored in the iOS Keychain,
  entered once during initial setup.
- There are exactly two users; the backend stores user profiles in a
  simple document collection. No role-based access control, no sessions,
  no signup endpoint.
- API keys are generated server-side and shared out-of-band (e.g., text
  message). No self-registration.
- The Profile screen displays the authenticated user's name, workout
  count, and personal metrics.
- This simplicity MUST be preserved even as features are added; any
  proposal that introduces general multi-tenancy, RBAC, or user
  management UI MUST be rejected.

### VII. Data Portability

Workout history MUST be importable from Strong's CSV export format and
the system MUST be capable of exporting data in a standard format.

- The app MUST include a one-time import path for the Strong CSV format
  (columns: Date, Workout Name, Duration, Exercise Name, Set Order,
  Weight, Reps, Distance, Seconds, RPE).
- Internal data models MAY differ from the CSV schema, but the import
  MUST map all Strong fields without data loss.
- The system SHOULD support exporting workout history to CSV or JSON for
  backup purposes.
- Exercise names from Strong MUST be normalized and matched to the
  internal exercise database during import.

## Technology Stack & Architecture

- **Target device**: iPhone 13 (no Dynamic Island; lock screen Live
  Activity only).
- **Client**: Swift 5.9+, SwiftUI, iOS 17+ minimum deployment target.
- **Frameworks**: ActivityKit (Live Activities), SwiftData or Core Data
  (local persistence), Swift Charts (graphs), WidgetKit (if home screen
  widget desired), BackgroundTasks framework (timer reliability).
- **Backend**: Python (FastAPI or similar) deployed on Railway.
- **Database**: PostgreSQL hosted on Railway.
- **Sync model**: Local-first. The iOS app writes to local storage
  immediately and syncs to the server asynchronously. Server is the
  long-term backup and enables future cross-device access but is never
  on the critical path for recording a workout.
- **API auth**: Single API key in the `Authorization` header; Keychain
  storage on client, environment variable on server.
- **Package management**: Swift Package Manager for iOS dependencies;
  uv for Python backend dependencies (NEVER pip).

## Development Workflow

- Features MUST be developed behind feature branches and merged via PR.
- Each feature MUST have a spec, plan, and task list before implementation
  begins (using the Specify workflow).
- The iOS app MUST compile and run in Xcode with zero warnings before a
  feature is considered complete.
- Backend endpoints MUST have integration tests covering the happy path
  and primary error cases.
- Commits MUST NOT be made without explicit direction; never auto-commit.
- CLAUDE.md and README.md MUST be checked for needed updates before any
  commit that changes architecture.

## Governance

This constitution is the authoritative source of project principles and
constraints. It supersedes all other documentation when conflicts arise.

- **Amendments** require: (1) a documented rationale, (2) an updated
  version number following semantic versioning, and (3) a sync impact
  check against all dependent templates.
- **Version policy**: MAJOR for principle removals or redefinitions,
  MINOR for new principles or material expansions, PATCH for wording
  and clarification changes.
- **Compliance**: Every spec, plan, and task list MUST include a
  constitution check verifying alignment with these principles before
  implementation proceeds.
- **Guidance file**: Use CLAUDE.md for runtime development guidance that
  supplements (but does not override) this constitution.

**Version**: 1.1.0 | **Ratified**: 2026-02-22 | **Last Amended**: 2026-03-08
