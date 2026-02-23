# Implementation Plan: Workout MVP

**Branch**: `001-workout-mvp` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-workout-mvp/spec.md`

## Summary

Build the core workout logging experience for Kiln: a SwiftUI iOS app with
three tabs (Workout, History, Profile) that allows one-tap workout start
from templates, inline set completion with rest timers, mid-workout
modifications, crash-safe persistence via SwiftData, and Strong CSV import.
The MVP is fully offline with no server sync. Architecture uses @Observable
session management + SwiftData direct binding + local notifications for
background timer alerts.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, Swift Charts, UserNotifications
**Storage**: SwiftData (SQLite-backed, local-first, autosave disabled)
**Testing**: XCTest (unit + UI tests)
**Target Platform**: iOS 17+, iPhone 13
**Project Type**: Mobile app (iOS)
**Performance Goals**: <100ms data persistence on set completion; rest timer
alerts within 1 second of target time
**Constraints**: Fully offline; no network dependency; single user; zero
data loss on crash/force-quit
**Scale/Scope**: 1 user, ~1,734 imported rows, 3 screens, ~6 entity types

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Zero Data Loss | PASS | SwiftData with autosave disabled + explicit `save()` after every set completion. Crash recovery via `isInProgress` flag on Workout entity. Atomic writes via `transaction {}`. |
| II. Minimal Friction | PASS | One-tap template start (FR-003). One-tap set completion (FR-005). Pre-fill from global exercise history. Two-tap exercise add (FR-009). Tab bar always visible (FR-001). |
| III. Timer Reliability | PASS | UNUserNotificationCenter for background/locked alerts. Timer end date persisted to UserDefaults. Foreground countdown derived from wall clock. Scene phase sync on app return. |
| IV. Live Activity First | N/A | Explicitly out of scope for this MVP per user direction. |
| V. Beautiful & Joyful Design | PASS | SwiftUI native patterns. Swift Charts for workouts/week. Consistent design system. No custom chrome. |
| VI. Single-User Simplicity | PASS | No auth, no user table, no multi-tenant code. Hardcoded profile. API key deferred (no server in MVP). |
| VII. Data Portability | PASS | Strong CSV import with all 10 fields mapped. Template auto-creation for 2 active routines. Exercise auto-creation from import. |

**Post-Phase 1 re-check**: All principles still PASS. No violations introduced by design decisions.

## Project Structure

### Documentation (this feature)

```text
specs/001-workout-mvp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Kiln/
├── KilnApp.swift                  # App entry point, ModelContainer, environment setup
├── Models/
│   ├── Exercise.swift             # @Model: named movement with type
│   ├── WorkoutTemplate.swift      # @Model: template with ordered exercises
│   ├── TemplateExercise.swift     # @Model: exercise within a template
│   ├── Workout.swift              # @Model: workout session (in-progress or completed)
│   ├── WorkoutExercise.swift      # @Model: exercise within a workout
│   ├── WorkoutSet.swift           # @Model: individual set data
│   └── ExerciseType.swift         # Enum: strength, cardio, bodyweight
├── Views/
│   ├── ContentView.swift          # TabView with 3 tabs
│   ├── Workout/
│   │   ├── StartWorkoutView.swift     # Template grid + "Start Empty" button
│   │   ├── TemplateCardView.swift     # Individual template card in grid
│   │   ├── ActiveWorkoutView.swift    # Active workout: exercise list + timer
│   │   ├── ExerciseCardView.swift     # Exercise with set rows during workout
│   │   ├── SetRowView.swift           # Individual set row (weight/reps/check)
│   │   ├── RestTimerView.swift        # Timer countdown display
│   │   └── ExercisePickerView.swift   # Searchable exercise selector
│   ├── Templates/
│   │   ├── TemplateEditorView.swift   # Create/edit template
│   │   └── TemplateExerciseRow.swift  # Exercise row in template editor
│   ├── History/
│   │   ├── HistoryListView.swift      # Chronological workout list
│   │   ├── WorkoutCardView.swift      # Summary card in history
│   │   └── WorkoutDetailView.swift    # Full workout detail view
│   └── Profile/
│       ├── ProfileView.swift          # Name, photo, count, chart
│       └── WorkoutsPerWeekChart.swift # Swift Charts bar chart
├── Services/
│   ├── WorkoutSessionManager.swift    # @Observable: active workout state + rest timer
│   ├── RestTimerService.swift         # UNUserNotificationCenter + UserDefaults persistence
│   ├── CSVImportService.swift         # Strong CSV parser + @ModelActor batch import
│   └── PreFillService.swift           # Query previous set data for exercise pre-fill
├── Design/
│   └── DesignSystem.swift             # Colors, typography, spacing constants
└── KilnTests/
    ├── CSVImportTests.swift           # CSV parsing and import validation
    ├── PreFillTests.swift             # Pre-fill query logic
    └── WorkoutSessionTests.swift      # Session manager state transitions
```

**Structure Decision**: Single iOS project (no backend for MVP). All code
lives under `Kiln/` as a standard Xcode project. The `Models/` directory
contains SwiftData `@Model` classes. `Views/` is organized by feature tab.
`Services/` contains non-UI logic (session management, timer, import,
pre-fill queries). No contracts directory needed since the MVP has no
external API.

## Complexity Tracking

> No constitution violations. No complexity justifications needed.
