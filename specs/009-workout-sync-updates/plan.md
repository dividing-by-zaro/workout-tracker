# Implementation Plan: Workout Sync Updates

**Branch**: `009-workout-sync-updates` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-workout-sync-updates/spec.md`

## Summary

Currently, workout sync is unidirectional — workouts upload to the server on completion but edits and deletes in the history view are local-only. This feature adds PUT and DELETE endpoints to the backend and extends `WorkoutSyncService` to send updates when workouts are edited or deleted, with retry on network failure.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS), Python 3.12 (backend)
**Primary Dependencies**: SwiftUI, SwiftData (iOS); FastAPI, motor (backend)
**Storage**: SwiftData (local, source of truth), MongoDB (server backup via motor)
**Testing**: Manual Xcode testing (iOS); curl/manual (backend)
**Target Platform**: iOS 17+ (iPhone 13), Linux server (Coolify)
**Project Type**: Mobile app + API backend
**Performance Goals**: Sync completes within 10 seconds of user action
**Constraints**: Offline-capable, local-first, fire-and-forget network calls
**Scale/Scope**: 2 users, ~hundreds of workouts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Local SwiftData remains source of truth. Server sync is secondary and never gates recording. Sync failures queue locally and retry automatically. |
| II. Minimal Friction | PASS | No new user-facing steps. Sync happens automatically on edit dismiss and delete confirm. |
| III. Timer Reliability | N/A | No timer changes. |
| IV. Live Activity First | N/A | No Live Activity changes. |
| V. Beautiful & Joyful Design | N/A | No UI changes beyond wiring existing dismiss/delete actions. |
| VI. Household Simplicity | PASS | Uses existing per-user API key auth. No new auth flows. Endpoints scoped to authenticated user. |
| VII. Data Portability | PASS | Server backup becomes more accurate, improving data portability. |

**Post-Phase 1 re-check**: All gates still pass. Full-replace PUT reuses existing payload — no new data model complexity. DELETE is a simple removal scoped by user_id + local_id.

## Project Structure

### Documentation (this feature)

```text
specs/009-workout-sync-updates/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research decisions
├── data-model.md        # Sync state model (pending edits/deletes)
├── quickstart.md        # Implementation guide
├── contracts/
│   └── workout-sync-api.md  # PUT and DELETE API contracts
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
timer-backend/
└── main.py              # + PUT /api/workouts/{local_id}, DELETE /api/workouts/{local_id}

Kiln/
├── Services/
│   └── WorkoutSyncService.swift  # + updateWorkout(), deleteWorkout(), pending tracking, bulk retry
└── Views/
    └── History/
        ├── WorkoutEditView.swift      # + trigger edit sync on dismiss
        └── HistoryListView.swift      # + trigger delete sync on confirm
```

**Structure Decision**: No new files needed. All changes are additions to existing files — 1 backend file and 3 iOS files.

## Complexity Tracking

No constitution violations. No complexity justifications needed.
