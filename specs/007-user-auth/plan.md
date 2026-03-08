# Implementation Plan: User Authentication & Profiles

**Branch**: `007-user-auth` | **Date**: 2026-03-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-user-auth/spec.md`

## Summary

Add API key-based authentication for 2 users (developer + wife) to the Kiln workout tracker. The existing FastAPI timer-backend gains MongoDB for user storage and per-user API key validation. The iOS app gains a branded login screen (fire light theme), Keychain-based key storage, an auth gate that conditionally renders login vs main app, and user profile display in the Profile tab. This is phase 1 infrastructure — no workout data sync.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS) / Python 3.12+ (backend)
**Primary Dependencies**: SwiftUI, Security framework (iOS); FastAPI, motor (async MongoDB driver) (backend)
**Storage**: MongoDB (backend user profiles); iOS Keychain (API key); UserDefaults (cached profile)
**Testing**: Manual Xcode testing (iOS); curl/httpie for backend endpoint verification
**Target Platform**: iOS 17+ (iPhone 13) / Linux Docker container (backend)
**Project Type**: Mobile app + API backend
**Performance Goals**: Login validation < 2 seconds; app launch with cached auth < 0.5 seconds
**Constraints**: Offline-capable after initial auth; 2 users only; no signup flow
**Scale/Scope**: 2 users, 1 new screen (login), 3 new service files (iOS), 1 new DB dependency (backend)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Auth is additive — no changes to SwiftData workout storage. Offline-tolerant auth doesn't gate workout recording. |
| II. Minimal Friction | PASS | One-time API key paste. After initial login, app launches directly to main view. |
| III. Timer Reliability | PASS | Timer endpoints unchanged. Auth middleware adds ~1ms overhead per request. |
| IV. Live Activity First | PASS | No changes to Live Activity. Timer backend continues to work with per-user keys. |
| V. Beautiful & Joyful Design | PASS | Login screen uses DesignSystem colors, typography, grain texture. |
| **VI. Single-User Simplicity** | **VIOLATION — JUSTIFIED** | See Complexity Tracking below. |
| VII. Data Portability | PASS | CSV import unchanged. |

**Post-Phase 1 re-check**: All gates still pass. The design adds a `users` collection but no RBAC, no sessions, no user management UI. The violation is minimal and justified.

## Project Structure

### Documentation (this feature)

```text
specs/007-user-auth/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: entities and state transitions
├── quickstart.md        # Phase 1: setup instructions
├── contracts/
│   └── auth-api.md      # Phase 1: API endpoint contracts
├── checklists/
│   └── requirements.md  # Spec quality validation
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
timer-backend/
├── main.py              # Modified: MongoDB connection, updated auth middleware, GET /api/me
├── db.py                # NEW: MongoDB client + seed_users() function
├── apns.py              # Unchanged
├── pyproject.toml       # Modified: add motor dependency
├── Dockerfile           # Modified: copy db.py
└── .env.example         # Modified: add MONGODB_URL

Kiln/
├── KilnApp.swift        # Modified: inject AuthService, conditional login/main rendering
├── Services/
│   ├── AuthService.swift         # NEW: @Observable auth state, login/logout, Keychain ops
│   ├── KeychainService.swift     # NEW: Keychain CRUD wrapper (save/load/delete)
│   └── TimerBackendService.swift # Modified: read API key from Keychain instead of Info.plist
├── Views/
│   ├── LoginView.swift           # NEW: branded login screen with API key field
│   └── Profile/
│       └── ProfileView.swift     # Modified: display user name from AuthService, add logout button
└── Design/
    └── DesignSystem.swift        # Unchanged (login view uses existing tokens)
```

**Structure Decision**: Follows the existing mobile + API pattern. No new directories — new files slot into existing `Services/` and `Views/` folders. Backend gains one new file (`db.py`) for MongoDB concerns.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Principle VI: adds `users` collection and per-user API keys (was single-user, no user tables) | Developer's wife needs her own identity and data isolation for future workout sync | Single shared API key cannot distinguish between users — the one key approach has already been outgrown. The change is minimal: 2 seeded documents, key-based lookup in middleware, no RBAC/sessions/signup. |

**Constitution amendment required**: Principle VI should be updated from "Single-User Simplicity" to "Household Simplicity" — exactly 2 users, API key auth, no general multi-tenancy. This amendment should be made during implementation.
