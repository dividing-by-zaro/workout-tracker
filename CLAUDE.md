# Kiln Development Guidelines

## Active Technologies

- Swift 5.9+ / SwiftUI / iOS 17+ (iPhone 13 target)
- SwiftData (local persistence, autosave disabled, explicit save on every set)
- Swift Charts (workouts-per-week bar chart)
- ActivityKit + WidgetKit + AppIntents (Live Activity on lock screen)
- App Groups (`group.app.izaro.kiln`) for shared UserDefaults (rest timer persistence + Live Activity cache)

## Architecture

- **@Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer, live activity lifecycle; `static var shared` singleton for intent access
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer
- **TabView** with conditional content in Workout tab (template grid vs. active workout)
- **Rest timer**: inline below completed set (auto-hides when done), `Date` end-time in UserDefaults + wall-clock-derived foreground countdown; `lastCompletedSetId` on `WorkoutSessionManager` tracks placement; `AlertConfiguration(sound: .default)` plays sound via Live Activity update on expiry
- **Live Activity**: Lock screen widget for completing entire workout without unlocking. Three views: `SetView` (adjustable weight/reps + Complete button), `TimerView` (countdown + Skip button + next set preview), `CompleteView` (all sets done). Interactive buttons via `LiveActivityIntent` (runs in app process). TimerView shows "Next:" preview with weight/reps of upcoming set; includes exercise name when crossing exercise boundaries (detected via `setNumber == 1`).
- **LiveActivityCache**: `enum` with static methods backed by App Group UserDefaults. Intent handlers read/write cached `ContentState` (zero SwiftData access — even in-memory reads trigger FaceID on lock screen). Cache keys: `la.state` (JSON-encoded ContentState), `la.setId`, `la.restDuration`, `la.dirty`, `la.dirtySetId`, `la.completedSetIds`. Pending completions applied to in-memory model on timer expiry (`applyPendingCompletionsInMemory`). Foreground resume syncs cache → SwiftData via `syncCacheToSwiftData()`.
- **BackgroundAudioService**: Plays silent audio to keep the app process alive in background (required for rest timer expiry and Live Activity updates). Also plays `alert_tone.caf` via `playAlertSound()` on timer expiry — the active `.playback` session suppresses `AlertConfiguration(sound:)`, so the alert must go through `AVAudioPlayer` directly.
- **Intent split pattern**: Shared struct declarations in `Kiln/Shared/`, app-target `perform()` with real logic in `Kiln/Intents/`, widget-target stubs in `KilnWidgets/`. Widget extension cannot access SwiftData.
- **CSV import**: `@ModelActor` background actor with batched saves

## Build

- Xcode project generated via `xcodegen` from `project.yml` at repo root
- Run `xcodegen generate` after adding/removing Swift files to regenerate `Kiln.xcodeproj`
- Open `Kiln.xcodeproj` in Xcode, build with Cmd+R
- Bundle IDs: `app.izaro.kiln` (app), `app.izaro.kiln.kilnwidgets` (widget extension)
- Development Team: `85S8MAN3A4`

## Project Structure

```text
Kiln/
├── KilnApp.swift                  # App entry, ModelContainer (autosave off), environment, foreground resume
├── Models/                        # 9 files: ExerciseType, EquipmentType, BodyPart, Exercise,
│                                  #   WorkoutTemplate, TemplateExercise, Workout, WorkoutExercise, WorkoutSet
├── Views/
│   ├── ContentView.swift          # 3-tab TabView with conditional Workout tab
│   ├── Workout/                   # StartWorkoutView, ActiveWorkoutView, SetRowView,
│   │                              #   ExerciseCardView, TemplateCardView, RestTimerView,
│   │                              #   ExercisePickerView, SwipeToDelete,
│   │                              #   NumericKeyboardView, CustomInputTextField
│   ├── Templates/                 # TemplateEditorView, TemplateExerciseRow
│   ├── History/                   # HistoryListView, WorkoutCardView, WorkoutDetailView,
│   │                              #   WorkoutEditView
│   └── Profile/                   # ProfileView, WorkoutsPerWeekChart
├── Services/                      # WorkoutSessionManager, RestTimerService, LiveActivityService,
│                                  #   LiveActivityCache, BackgroundAudioService, CSVImportService, PreFillService
├── Shared/                        # WorkoutActivityAttributes, WorkoutLiveActivityIntents (shared with widget)
├── Intents/                       # WorkoutLiveActivityIntents+App (perform() bodies)
├── Assets.xcassets/               # App icon + body part icons + brick_icon + noise_tile
└── Design/                        # DesignSystem (colors, shadows, grain, corner radius, typography, spacing, icons)

KilnWidgets/
├── KilnWidgetBundle.swift         # @main WidgetBundle + ActivityConfiguration
├── Views/                         # SetView, TimerView, CompleteView (lock screen presentations)
├── WorkoutLiveActivityIntents+Widget.swift  # Stub perform() bodies
└── Assets.xcassets/               # 7 widget color sets (WidgetPrimary, WidgetBackground, etc.)
```

## Key Decisions

- All data local-first, no server sync in MVP
- Single user — no auth, no user tables
- Exercises seeded from Strong CSV import + created on-the-fly
- Weight in lbs only
- Templates auto-created from import for "New Legs/full Body A" and "New Legs/full Body B" only
- Pre-fill from most recent workout containing that exercise (matched by unique exercise name, not persistentModelID); previous column shows "55 lbs x 8" format
- **EquipmentType** (9 cases) with `equipmentCategory` computed property mapping to 5 display categories: weightReps, repsOnly, duration, distance, weightDistance — used by Live Activity for adaptive input fields
- **BodyPart** (9 cases) with custom PNG icons in asset catalog (template rendering mode for tint color)
- Body part + equipment type are pre-enriched in the CSV — no runtime inference needed for imported data
- **Theme**: Fire light theme — warm cream backgrounds, fire red primary accent (#BF3326), warm brown/charcoal secondary tones, grain texture overlay (multiply blend), warm-tinted shadows
- **DesignSystem** expanded: 14 color tokens, Shadows (cardShadow, elevatedShadow), CornerRadius, GrainedBackground modifier (multiply blend, 0.12 opacity), CardGrainOverlay view (0.06 opacity)
- Forced light mode via Info.plist `UIUserInterfaceStyle: Light` + `.preferredColorScheme(.light)`
- **Live Activity timer display**: `Text(timerInterval:countsDown:)` shows "1:--" on Simulator (reduced fidelity mode) — works correctly on real device. `ProgressView(timerInterval:countsDown:)` for auto-updating progress bar.
- **No push notifications**: Rest timer sound played via `AVAudioPlayer` in `BackgroundAudioService.playAlertSound()` (AlertConfiguration kept for visual banner only). No `UNUserNotificationCenter` usage.

## Spec Artifacts

Feature specs, plans, and tasks live in `specs/001-workout-mvp/`, `specs/002-visual-redesign/`, `specs/003-live-activity/`, and `specs/004-reliable-rest-timer/`.
Constitution at `.specify/memory/constitution.md`.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
