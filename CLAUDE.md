# Kiln Development Guidelines

## Active Technologies
- Swift 5.9+ (iOS client), Python 3.12 (backend) + SwiftUI, SwiftData (iOS); FastAPI, motor, Pydantic (backend) (008-workout-history-sync)
- SwiftData (local, source of truth), MongoDB (server backup via motor async driver) (008-workout-history-sync)
- Swift 5.9+ (iOS), Python 3.12 (backend) + SwiftUI, SwiftData (iOS); FastAPI, motor (backend) (009-workout-sync-updates)
- SwiftData (local, source of truth), MongoDB (server backup via motor) (009-workout-sync-updates)
- Swift 5.9+ + SwiftUI, SwiftData (010-exercise-history)
- SwiftData (local, existing models — no new entities) (010-exercise-history)

- Swift 5.9+ / SwiftUI / iOS 17+ (iPhone 13 target)
- SwiftData (local persistence, autosave disabled, explicit save on every set)
- Swift Charts (workouts-per-week bar chart)
- ActivityKit + WidgetKit + AppIntents (Live Activity on lock screen)
- App Groups (`group.app.izaro.kiln`) for shared UserDefaults (rest timer persistence + Live Activity cache)
- Security framework (iOS Keychain for API key storage)
- Python 3.12 / FastAPI / motor (async MongoDB driver) / httpx[http2] / PyJWT (backend)
- MongoDB (user profiles, document-based flexible schema)

## Architecture

- **@MainActor @Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer, live activity lifecycle; `static var shared` singleton for intent access. All service classes (`WorkoutSessionManager`, `RestTimerService`, `LiveActivityService`, `BackgroundAudioService`, `NotificationService`, `TimerBackendService`, `AuthService`) are `@MainActor`-isolated.
- **WorkoutSyncService**: `@MainActor @Observable` class handling device→server workout sync. Uploads completed workouts via `POST /api/workouts` (idempotent, deduped by `local_id`). Tracks synced workout IDs in UserDefaults (`syncedWorkoutIds`). Bulk sync on launch via `syncAllPending(context:)`, per-workout sync on finish via `WorkoutSessionManager.syncService`. Profile shows sync status (pending count vs backed up). Backend stores workouts in MongoDB `workouts` collection with embedded exercises/sets; exercises deduped in `exercises` collection. Edit sync: `markWorkoutEdited()` + `updateWorkout()` sends `PUT /api/workouts/{local_id}` on WorkoutEditView dismiss. Delete sync: `markWorkoutDeleted()` + `deleteWorkoutFromServer()` sends `DELETE /api/workouts/{local_id}` on HistoryListView delete. Pending edits/deletes tracked in UserDefaults (`pendingEditWorkoutIds`, `pendingDeleteWorkoutIds`) and retried in `syncAllPending()`. Delete supersedes edit (deduplication). On launch, `syncAllPending` reconciles with server via `GET /api/workouts/ids`: rebuilds `syncedWorkoutIds` from server truth, deletes server-side orphans (workouts on server but not on device), uploads missing workouts. Client-authoritative — device state always wins.
- **AuthService**: `@MainActor @Observable` class managing authentication state. Stores API key in iOS Keychain via `KeychainService`, caches user profile in UserDefaults. Auth gate in `KilnApp.swift` conditionally renders `LoginView` or `ContentView`. On launch, checks Keychain for stored key and silently validates with backend; falls back to cached profile if offline. Per-user API keys replace the shared build-time `TIMER_BACKEND_API_KEY`.
- **KeychainService**: `enum` with static methods (`save`/`load`/`delete`) wrapping Security framework. Service name `app.izaro.kiln`, account-based key lookup.
- **LoginView**: Branded splash/login screen with fire light theme (grain background, flame icon, API key text field, Connect button). Shown when no valid API key is stored.
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer. Periodic save (1s tick) in elapsed timer prevents data loss from in-flight `@Bindable` field edits.
- **TabView** with `selection` binding and `.tag()` — 4 tabs: Workouts (0), History (1), Exercises (2), Profile (3). Supports deep link tab switching from Live Activity via `onOpenURL`.
- **Exercise History Browser**: `ExerciseListView` shows all exercises alphabetically via `@Query(sort: \Exercise.name)` with `.searchable()` filtering. `ExerciseHistoryView` queries all finished workouts and filters in-memory by `exercise.id` (UUID) to find matching `WorkoutExercise` entries — avoids SwiftData `#Predicate` limitations with relationship traversal. Displays workout session cards with equipment-type-aware set formatting (mirrors `WorkoutDetailView.setDetailLabel` logic).
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
- **Secrets**: `Secrets.xcconfig` (gitignored) provides `TIMER_BACKEND_URL` at build time via Info.plist. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` and fill in values. API key is no longer build-time — it's entered at runtime via login screen and stored in iOS Keychain.

## Project Structure

```text
Kiln/
├── KilnApp.swift                  # App entry, ModelContainer (autosave off), environment, auth gate, foreground resume
├── Models/                        # 10 files: ExerciseType, EquipmentType, BodyPart, Exercise,
│                                  #   WorkoutTemplate, TemplateExercise, Workout, WorkoutExercise, WorkoutSet,
│                                  #   CelebrationData
├── Views/
│   ├── LoginView.swift             # API key login screen (shown when unauthenticated)
│   ├── ContentView.swift          # 4-tab TabView with conditional Workout tab
│   ├── Exercises/                 # ExerciseListView, ExerciseHistoryView
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
│                                  #   TimerBackendService, CSVImportService, PreFillService,
│                                  #   AuthService, KeychainService, WorkoutSyncService
├── Shared/                        # WorkoutActivityAttributes, WorkoutLiveActivityIntents (shared with widget)
├── Intents/                       # WorkoutLiveActivityIntents+App (perform() bodies)
├── Assets.xcassets/               # App icon + body part icons + brick_icon + noise_tile
└── Design/                        # DesignSystem (colors, shadows, grain, corner radius, typography, spacing, icons)

timer-backend/
├── main.py              # FastAPI app: /api/me, /api/timer/schedule, /api/timer/cancel, /api/workouts (POST/PUT/DELETE), /api/workouts/status, /api/workouts/ids, /health
├── models.py            # Pydantic models for workout sync payloads (WorkoutPayload, WorkoutResponse, SyncStatusResponse)
├── db.py                # MongoDB client (motor), user seeding (names via SEED_USER_NAMES env var), ensure_indexes(), get_db() helper
├── seed_demo.py         # Script to seed a demo user + sample workouts (split approach: mongosh for user, API for workouts)
├── apns.py              # APNSClient: ES256 JWT signing, HTTP/2 push to APNS
├── Dockerfile           # Multi-stage Python 3.12 + uv build for Coolify
├── pyproject.toml       # Dependencies managed by uv
└── .env.example         # APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH or APNS_KEY_BASE64, MONGODB_URL, APNS_ENVIRONMENT, SEED_USER_NAMES

scripts/
├── frame_screenshots.py           # Adds iPhone device frames to PNG screenshots (Pillow)
└── generate_banner.py             # Generates README banner with app icon, grain texture, title (Pillow + numpy)

screenshots/                       # Framed screenshots + banner for README (committed, gitignore exception)

KilnWidgets/
├── KilnWidgetBundle.swift         # @main WidgetBundle + ActivityConfiguration
├── Views/                         # SetView, TimerView, CompleteView (lock screen presentations)
├── WorkoutLiveActivityIntents+Widget.swift  # Stub perform() bodies
└── Assets.xcassets/               # 7 widget color sets (WidgetPrimary, WidgetBackground, etc.)
```

## Key Decisions

- All data local-first, no server sync in MVP
- Two household users (developer + wife) — per-user API key auth, no signup, no RBAC
- **Authentication**: API keys stored in iOS Keychain (not UserDefaults). Keys are `kiln_`-prefixed random tokens generated server-side and shared out-of-band. Backend validates via MongoDB `users` collection lookup in auth middleware.
- **Auth flow**: `AuthService` checks Keychain on launch → if key found, show main app immediately + silently validate with backend → if 401, force logout → if network error, proceed with cached profile. Login screen shown only when no key stored.
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
- **Timer backend**: `timer-backend/` is a FastAPI microservice deployed on Coolify. Accepts timer schedule requests, sleeps for the duration, then sends APNS push-to-update to transition the Live Activity from timer view to next set view. In-memory timers + MongoDB for user profiles. Per-user API key auth (keys stored in `users` collection). Backend URL provided via `Secrets.xcconfig` → Info.plist → `Bundle.main`. API contracts in `specs/006-hybrid-timer-backend/contracts/timer-api.md` and `specs/007-user-auth/contracts/auth-api.md`.
- **TimerBackendService**: `@MainActor` HTTP client in `Kiln/Services/TimerBackendService.swift`. Reads `TimerBackendURL` from Info.plist and API key from Keychain. Fire-and-forget `scheduleTimer()` and `cancelTimer()` calls. Called from `WorkoutSessionManager` on set completion (schedule) and skip/finish/discard (cancel).
- **Live Activity push token**: `LiveActivityService.startActivity()` tries `pushType: .token` first, falls back to `pushType: nil` if APNS entitlement isn't provisioned. `observePushToken(activity:onToken:)` iterates `activity.pushTokenUpdates` async sequence. Token stored in `WorkoutSessionManager.currentPushToken`, persisted to `LiveActivityCache.pushToken`, and sent to backend with each schedule request. On app restart, `reconnectLiveActivity()` restores the token from cache since `pushTokenUpdates` does not re-emit for existing activities.

## Spec Artifacts

Feature specs, plans, and tasks live in `specs/001-workout-mvp/`, `specs/002-visual-redesign/`, `specs/003-live-activity/`, `specs/004-reliable-rest-timer/`, `specs/005-celebration-screen/`, `specs/006-hybrid-timer-backend/`, `specs/007-user-auth/`, `specs/008-workout-history-sync/`, `specs/009-workout-sync-updates/`, and `specs/010-exercise-history/`.
Constitution at `.specify/memory/constitution.md`.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

## Recent Changes
- 010-exercise-history: Added Swift 5.9+ + SwiftUI, SwiftData
- 009-workout-sync-updates: Added Swift 5.9+ (iOS), Python 3.12 (backend) + SwiftUI, SwiftData (iOS); FastAPI, motor (backend)
- 008-workout-history-sync: Added Swift 5.9+ (iOS client), Python 3.12 (backend) + SwiftUI, SwiftData (iOS); FastAPI, motor, Pydantic (backend)
