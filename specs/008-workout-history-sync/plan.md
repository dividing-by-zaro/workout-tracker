# Implementation Plan: Workout History Sync

**Branch**: `008-workout-history-sync` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-workout-history-sync/spec.md`

## Summary

Add one-directional workout history sync from the iOS app to the MongoDB backend. On first connection, all completed local workouts are bulk-uploaded. After that, each newly completed workout is automatically sent to the server. The backend stores workouts with their full exercise/set hierarchy in MongoDB, with exercises deduplicated per user. Sync state is tracked locally in UserDefaults to prevent duplicates and enable retry of failed uploads.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS client), Python 3.12 (backend)
**Primary Dependencies**: SwiftUI, SwiftData (iOS); FastAPI, motor, Pydantic (backend)
**Storage**: SwiftData (local, source of truth), MongoDB (server backup via motor async driver)
**Testing**: Manual Xcode testing (iOS), curl/manual backend testing
**Target Platform**: iOS 17+ (iPhone 13)
**Project Type**: Mobile app + API backend
**Performance Goals**: Bulk sync of 1000 workouts < 30s; single workout sync < 5s
**Constraints**: Sync must not block UI; offline-tolerant; no data loss
**Scale/Scope**: 2 users, <1000 workouts each

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Local-first — SwiftData is source of truth. Sync is secondary backup. Failed syncs queue and retry. |
| II. Minimal Friction | PASS | Sync is fully automatic — no user action required. |
| III. Timer Reliability | N/A | No timer changes. |
| IV. Live Activity First | N/A | No Live Activity changes. |
| V. Beautiful & Joyful Design | PASS | Sync status on Profile uses existing design system. |
| VI. Household Simplicity | PASS | Uses existing per-user API key auth. No new user management. |
| VII. Data Portability | PASS | Synced data in MongoDB enables future export. |

**Post-design re-check**: All gates still pass. The design uses existing auth middleware, existing backend infrastructure, and simple UserDefaults for sync state — no new complexity patterns introduced.

## Project Structure

### Documentation (this feature)

```text
specs/008-workout-history-sync/
├── plan.md              # This file
├── research.md          # Phase 0: design decisions and rationale
├── data-model.md        # Phase 1: MongoDB collection schemas
├── quickstart.md        # Phase 1: developer setup guide
├── contracts/
│   └── sync-api.md      # Phase 1: API endpoint contracts
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
timer-backend/
├── main.py              # Add POST /api/workouts, GET /api/workouts/status endpoints
├── models.py            # NEW: Pydantic models for workout sync payloads
└── db.py                # Add index creation for exercises + workouts collections

Kiln/
├── KilnApp.swift                  # Inject WorkoutSyncService, trigger sync on launch
├── Services/
│   ├── WorkoutSyncService.swift   # NEW: @MainActor @Observable sync service
│   └── WorkoutSessionManager.swift # Call sync after finishWorkout()
└── Views/
    └── Profile/
        └── ProfileView.swift      # Display sync status indicator
```

**Structure Decision**: Extends existing backend (timer-backend/) and iOS app (Kiln/) with minimal new files. One new Swift service file, one new Python models file, and modifications to 4 existing files.

## Complexity Tracking

No constitution violations — table not needed.
