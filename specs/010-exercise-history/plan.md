# Implementation Plan: Exercise History Browser

**Branch**: `010-exercise-history` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-exercise-history/spec.md`

## Summary

Add a new "Exercises" tab to the main tab bar that lists all exercises alphabetically with search. Tapping an exercise navigates to a history view showing every past workout session where that exercise was performed, with full set details displayed per equipment type. Purely client-side — reads existing SwiftData models with no new entities or backend changes.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData
**Storage**: SwiftData (local, existing models — no new entities)
**Testing**: Manual in Xcode (no XCTest suite in project)
**Target Platform**: iOS 17+ (iPhone 13)
**Project Type**: Mobile app (iOS)
**Performance Goals**: Exercise list loads within 1 second, 60 fps scrolling
**Constraints**: Local-only data, offline-capable by default
**Scale/Scope**: 2 users, ~100-500 exercises, ~100-1000 past workouts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Read-only feature — no writes, no risk of data loss |
| II. Minimal Friction | PASS | 2 taps to view any exercise's history (tab → exercise) |
| III. Timer Reliability | N/A | No timer interaction |
| IV. Live Activity First | N/A | No Live Activity changes |
| V. Beautiful & Joyful Design | PASS | Reuses existing design system (cards, grain, fire light theme) |
| VI. Household Simplicity | PASS | No auth changes, no multi-tenancy concerns |
| VII. Data Portability | N/A | No import/export changes |

**Post-Design Re-check**: All gates still pass. No new models, no new APIs, no complexity additions.

## Project Structure

### Documentation (this feature)

```text
specs/010-exercise-history/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Research decisions
├── data-model.md        # Data model documentation
├── quickstart.md        # Developer quickstart guide
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
Kiln/
├── Views/
│   └── Exercises/                          # NEW directory
│       ├── ExerciseListView.swift          # NEW — alphabetical exercise list with search
│       └── ExerciseHistoryView.swift       # NEW — per-exercise workout history
├── Design/
│   └── DesignSystem.swift                  # MODIFIED — add Icon.exercises
└── Views/
    └── ContentView.swift                   # MODIFIED — add 4th tab, shift Profile tag
```

**Structure Decision**: Two new view files in a new `Exercises/` subdirectory under `Views/`, following the existing pattern of grouping related views (Workout/, History/, Templates/, Profile/). No new models, services, or tests directories needed.

## Complexity Tracking

No constitution violations. No complexity justifications needed.
