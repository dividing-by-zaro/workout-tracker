# Kiln Development Guidelines

## Active Technologies

- Swift 5.9+ / SwiftUI / iOS 17+ (iPhone 13 target)
- SwiftData (local persistence, autosave disabled, explicit save on every set)
- Swift Charts (workouts-per-week bar chart)
- UserNotifications (background rest timer alerts)

## Architecture

- **@Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer
- **TabView** with conditional content in Workout tab (template grid vs. active workout)
- **Rest timer**: `UNUserNotificationCenter` for background alerts + `Date` end-time in UserDefaults + wall-clock-derived foreground countdown
- **CSV import**: `@ModelActor` background actor with batched saves

## Project Structure

```text
Kiln/
├── KilnApp.swift
├── Models/         # SwiftData @Model classes (Exercise, Workout, WorkoutSet, etc.)
├── Views/          # SwiftUI views organized by tab (Workout/, History/, Profile/, Templates/)
├── Services/       # WorkoutSessionManager, RestTimerService, CSVImportService, PreFillService
├── Design/         # DesignSystem (colors, typography, spacing)
└── KilnTests/
```

## Key Decisions

- All data local-first, no server sync in MVP
- Single user — no auth, no user tables
- Exercises seeded from Strong CSV import + created on-the-fly
- Weight in lbs only
- Templates auto-created from import for "New Legs/full Body A" and "New Legs/full Body B" only
- Pre-fill from most recent workout containing that exercise (global, per-set)

## Spec Artifacts

Feature specs, plans, and tasks live in `specs/001-workout-mvp/`.
Constitution at `.specify/memory/constitution.md`.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
