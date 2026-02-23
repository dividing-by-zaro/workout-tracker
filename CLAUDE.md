# Kiln Development Guidelines

## Active Technologies

- Swift 5.9+ / SwiftUI / iOS 17+ (iPhone 17 target)
- SwiftData (local persistence, autosave disabled, explicit save on every set)
- Swift Charts (workouts-per-week bar chart)
- UserNotifications (background rest timer alerts)

## Architecture

- **@Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer
- **TabView** with conditional content in Workout tab (template grid vs. active workout)
- **Rest timer**: `UNUserNotificationCenter` for background alerts + `Date` end-time in UserDefaults + wall-clock-derived foreground countdown
- **CSV import**: `@ModelActor` background actor with batched saves

## Build

- Xcode project generated via `xcodegen` from `project.yml` at repo root
- Run `xcodegen generate` after adding/removing Swift files to regenerate `Kiln.xcodeproj`
- Open `Kiln.xcodeproj` in Xcode, build with Cmd+R

## Project Structure

```text
Kiln/
├── KilnApp.swift                  # App entry, ModelContainer (autosave off), environment
├── Models/                        # 9 files: ExerciseType, EquipmentType, BodyPart, Exercise,
│                                  #   WorkoutTemplate, TemplateExercise, Workout, WorkoutExercise, WorkoutSet
├── Views/
│   ├── ContentView.swift          # 3-tab TabView with conditional Workout tab
│   ├── Workout/                   # StartWorkoutView, ActiveWorkoutView, SetRowView,
│   │                              #   ExerciseCardView, TemplateCardView, RestTimerView,
│   │                              #   ExercisePickerView
│   ├── Templates/                 # TemplateEditorView, TemplateExerciseRow
│   ├── History/                   # HistoryListView, WorkoutCardView, WorkoutDetailView
│   └── Profile/                   # ProfileView, WorkoutsPerWeekChart
├── Services/                      # WorkoutSessionManager, RestTimerService,
│                                  #   CSVImportService, PreFillService
├── Assets.xcassets/               # App icon + body part icons (bodypart_*.imageset)
└── Design/                        # DesignSystem (colors, typography, spacing, icons)
```

## Key Decisions

- All data local-first, no server sync in MVP
- Single user — no auth, no user tables
- Exercises seeded from Strong CSV import + created on-the-fly
- Weight in lbs only
- Templates auto-created from import for "New Legs/full Body A" and "New Legs/full Body B" only
- Pre-fill from most recent workout containing that exercise (global, per-set)
- **EquipmentType** (9 cases: barbell, dumbbell, kettlebell, machineOther, weightedBodyweight, repsOnly, duration, distance, weightedDistance) determines which input fields show per set
- **BodyPart** (9 cases) with custom PNG icons in asset catalog (template rendering mode for tint color)
- Body part + equipment type are pre-enriched in the CSV — no runtime inference needed for imported data
- Accent color: red (`DesignSystem.Colors.primary`)

## Spec Artifacts

Feature specs, plans, and tasks live in `specs/001-workout-mvp/`.
Constitution at `.specify/memory/constitution.md`.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
