# Kiln Development Guidelines

## Active Technologies

- Swift 5.9+ / SwiftUI / iOS 17+ (iPhone 13 target)
- SwiftData (local persistence, autosave disabled, explicit save on every set)
- Swift Charts (workouts-per-week bar chart)
- ActivityKit + WidgetKit + AppIntents (Live Activity on lock screen)
- App Groups (`group.app.izaro.kiln`) for shared UserDefaults (rest timer persistence + Live Activity cache)
- Python 3.12 / FastAPI / httpx[http2] / PyJWT (timer backend for APNS Live Activity push-to-update)

## Architecture

- **@MainActor @Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer, live activity lifecycle; `static var shared` singleton for intent access. All service classes (`WorkoutSessionManager`, `RestTimerService`, `LiveActivityService`, `BackgroundAudioService`, `NotificationService`, `TimerBackendService`) are `@MainActor`-isolated.
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer. Periodic save (1s tick) in elapsed timer prevents data loss from in-flight `@Bindable` field edits.
- **TabView** with `selection` binding and `.tag()` — supports deep link tab switching from Live Activity via `onOpenURL`
- **Rest timer**: inline below completed set (auto-hides when done), `Date` end-time in UserDefaults + wall-clock-derived foreground countdown; `lastCompletedSetId` on `WorkoutSessionManager` tracks placement. Display timer uses `RunLoop.common` mode so countdown updates during scroll. Local notification via `UNUserNotificationCenter` guarantees alert fires even when app is killed/backgrounded.
- **NotificationService**: `@MainActor @Observable` class conforming to `UNUserNotificationCenterDelegate`. Schedules `UNTimeIntervalNotificationTrigger` with `alert_tone.caf` custom sound on set completion; cancels on skip/finish/discard. Foreground delegate (`willPresent`) suppresses system banner — the in-app `playAlertSound()` + haptic handle foreground alerts instead. Permission requested on app launch.
- **Live Activity**: Lock screen widget for completing entire workout without unlocking. Three views: `SetView` (adjustable weight/reps + Complete button), `TimerView` (countdown + Skip button + next set preview), `CompleteView` (all sets done). Interactive buttons via `LiveActivityIntent` (runs in app process). TimerView shows "Next:" preview with weight/reps of upcoming set; includes exercise name when crossing exercise boundaries (detected via `setNumber == 1`).
- **LiveActivityCache**: `enum` with static methods backed by App Group UserDefaults. Intent handlers read/write cached `ContentState` (zero SwiftData access — even in-memory reads trigger FaceID on lock screen). Cache keys: `la.state` (JSON-encoded ContentState), `la.setId`, `la.restDuration`, `la.dirty`, `la.dirtySetId`, `la.completedSetIds`, `la.pushToken`. Push token persisted so it survives app kill — `reconnectLiveActivity()` restores it immediately since `activity.pushTokenUpdates` only emits on fresh activity creation, not reconnection. Pending completions applied to in-memory model on timer expiry (`applyPendingCompletionsInMemory`). Foreground resume syncs cache → SwiftData via `syncCacheToSwiftData()`.
- **BackgroundAudioService**: Plays `alert_tone.caf` via `playAlertSound()` on foreground timer expiry. Silent audio workaround removed — local notifications + APNS push handle background/killed timer alerts.
- **Intent split pattern**: Shared struct declarations in `Kiln/Shared/`, app-target `perform()` with real logic in `Kiln/Intents/`, widget-target stubs in `KilnWidgets/`. Widget extension cannot access SwiftData.
- **Template diff & update**: `TemplateDiff` struct compares workout exercises vs template exercises by `Exercise.id` (added/removed/moved counts). End-workout overlay conditionally shows "Finish & Update Template" button when exercises differ from the source template. `finishAndUpdateTemplate(context:)` replaces all `TemplateExercise` objects on the template with the workout's current exercise list.
- **Exercise reorder**: `ExerciseReorderView` provides drag-and-drop reordering of exercises during an active workout via a sheet.
- **Celebration screen**: `CelebrationData` struct snapshots workout stats (volume, sets, reps, distance, duration, workout count ordinal) at finish time. `CelebrationView` presented as `.fullScreenCover` on `ContentView` via `sessionManager.celebrationData`. Adaptive stat display uses `EquipmentType.tracksWeight/tracksReps/tracksDistance`. Ember particle animation via SwiftUI `Canvas` + `TimelineView`.
- **CSV import**: `@ModelActor` background actor with batched saves

## Build

- Xcode project generated via `xcodegen` from `project.yml` at repo root
- Run `xcodegen generate` after adding/removing Swift files to regenerate `Kiln.xcodeproj`
- Open `Kiln.xcodeproj` in Xcode, build with Cmd+R
- Bundle IDs: `app.izaro.kiln` (app), `app.izaro.kiln.kilnwidgets` (widget extension)
- Development Team: `85S8MAN3A4`
- **Secrets**: `Secrets.xcconfig` (gitignored) provides `TIMER_BACKEND_URL` and `TIMER_BACKEND_API_KEY` at build time via Info.plist. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` and fill in values.

## Project Structure

```text
Kiln/
├── KilnApp.swift                  # App entry, ModelContainer (autosave off), environment, foreground resume
├── Models/                        # 10 files: ExerciseType, EquipmentType, BodyPart, Exercise,
│                                  #   WorkoutTemplate, TemplateExercise, Workout, WorkoutExercise, WorkoutSet,
│                                  #   CelebrationData
├── Views/
│   ├── ContentView.swift          # 3-tab TabView with conditional Workout tab
│   ├── Workout/                   # StartWorkoutView, ActiveWorkoutView, SetRowView,
│   │                              #   ExerciseCardView, TemplateCardView, RestTimerView,
│   │                              #   ExercisePickerView, ExerciseReorderView, SwipeToDelete,
│   │                              #   NumericKeyboardView, CustomInputTextField, CelebrationView
│   ├── Templates/                 # TemplateEditorView, TemplateExerciseRow
│   ├── History/                   # HistoryListView, WorkoutCardView, WorkoutDetailView,
│   │                              #   WorkoutEditView
│   └── Profile/                   # ProfileView, WorkoutsPerWeekChart
├── Services/                      # WorkoutSessionManager, RestTimerService, LiveActivityService,
│                                  #   LiveActivityCache, BackgroundAudioService, NotificationService,
│                                  #   TimerBackendService, CSVImportService, PreFillService
├── Shared/                        # WorkoutActivityAttributes, WorkoutLiveActivityIntents (shared with widget)
├── Intents/                       # WorkoutLiveActivityIntents+App (perform() bodies)
├── Assets.xcassets/               # App icon + body part icons + brick_icon + noise_tile
└── Design/                        # DesignSystem (colors, shadows, grain, corner radius, typography, spacing, icons)

timer-backend/
├── main.py              # FastAPI app: /api/timer/schedule, /api/timer/cancel, /health
├── apns.py              # APNSClient: ES256 JWT signing, HTTP/2 push to APNS
├── Dockerfile           # Multi-stage Python 3.12 + uv build for Coolify
├── pyproject.toml       # Dependencies managed by uv
└── .env.example         # APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH or APNS_KEY_BASE64, API_KEY, APNS_ENVIRONMENT

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
- Pre-fill from most recent workout containing that exercise (matched by unique exercise name, not persistentModelID); previous column shows "55 lbs x 8" format. Pre-fill data cached in `@State` dict on views (keyed by exercise UUID) — computed once on appear and on exercise add/swap/remove, not on every re-render.
- **EquipmentType** (9 cases) with `equipmentCategory` computed property mapping to 5 display categories: weightReps, repsOnly, duration, distance, weightDistance — used by Live Activity for adaptive input fields
- **BodyPart** (9 cases) with custom PNG icons in asset catalog (template rendering mode for tint color)
- Body part + equipment type are pre-enriched in the CSV — no runtime inference needed for imported data
- **Theme**: Fire light theme — warm cream backgrounds, fire red primary accent (#BF3326), warm brown/charcoal secondary tones, grain texture overlay (multiply blend), warm-tinted shadows
- **DesignSystem** expanded: 14 color tokens, Shadows (cardShadow, elevatedShadow), CornerRadius, GrainedBackground modifier (multiply blend, 0.12 opacity), CardGrainOverlay view (0.06 opacity)
- Forced light mode via Info.plist `UIUserInterfaceStyle: Light` + `.preferredColorScheme(.light)`
- **Live Activity timer display**: `Text(timerInterval:countsDown:)` shows "1:--" on Simulator (reduced fidelity mode) — works correctly on real device. `ProgressView(timerInterval:countsDown:)` for auto-updating progress bar.
- **Local notifications for rest timer**: `NotificationService` schedules a `UNTimeIntervalNotificationTrigger` with `alert_tone.caf` when a set is completed. Fires reliably even when app is killed/backgrounded. `BackgroundAudioService.playAlertSound()` used for foreground alert sound.
- **Timer backend**: `timer-backend/` is a FastAPI microservice deployed on Coolify. Accepts timer schedule requests, sleeps for the duration, then sends APNS push-to-update to transition the Live Activity from timer view to next set view. In-memory timers (no database) — graceful degradation if backend is unavailable (local notification still fires). Single API key auth. Backend URL and API key provided via `Secrets.xcconfig` → Info.plist → `Bundle.main`. API contract in `specs/006-hybrid-timer-backend/contracts/timer-api.md`.
- **TimerBackendService**: `@MainActor` HTTP client in `Kiln/Services/TimerBackendService.swift`. Reads `TimerBackendURL` and `TimerBackendAPIKey` from Info.plist. Fire-and-forget `scheduleTimer()` and `cancelTimer()` calls. Called from `WorkoutSessionManager` on set completion (schedule) and skip/finish/discard (cancel).
- **Live Activity push token**: `LiveActivityService.startActivity()` tries `pushType: .token` first, falls back to `pushType: nil` if APNS entitlement isn't provisioned. `observePushToken(activity:onToken:)` iterates `activity.pushTokenUpdates` async sequence. Token stored in `WorkoutSessionManager.currentPushToken`, persisted to `LiveActivityCache.pushToken`, and sent to backend with each schedule request. On app restart, `reconnectLiveActivity()` restores the token from cache since `pushTokenUpdates` does not re-emit for existing activities.

## Spec Artifacts

Feature specs, plans, and tasks live in `specs/001-workout-mvp/`, `specs/002-visual-redesign/`, `specs/003-live-activity/`, `specs/004-reliable-rest-timer/`, `specs/005-celebration-screen/`, and `specs/006-hybrid-timer-backend/`.
Constitution at `.specify/memory/constitution.md`.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

