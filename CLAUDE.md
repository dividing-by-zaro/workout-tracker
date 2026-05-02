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

- **@MainActor @Observable** `WorkoutSessionManager` injected via `.environment()` — owns active workout state, rest timer, live activity lifecycle; `static var shared` singleton for intent access. All service classes (`WorkoutSessionManager`, `RestTimerService`, `LiveActivityService`, `NotificationService`, `TimerBackendService`, `AuthService`) are `@MainActor`-isolated. Internal `WorkoutSessionPersistenceController` debounces SwiftData saves (0.8s scheduled saves via `scheduleSave()`, explicit `saveNow()` at completion/start/finish boundaries) — replaces the previous per-second elapsed-timer save. Set completion is unified: both the app path (`completeSet(_:context:)`) and the Live Activity intent path (`completeCurrentSetFromIntent()`) build a `SetCompletionTransition` and funnel through `applySetCompletion` — single canonical state transition.
- **WorkoutHistoryService**: `enum` with static helpers for historical queries — `fetchCompletedWorkouts(context:)`, `exerciseSessions(forExerciseId:in:)`, `mostRecentHistoricalMatch(...)`, `templateSummary(...)`. Replaces repeated full-history scans in PreFillService, ChartDataService, ExerciseHistoryView, and WorkoutTemplate stats. `ActiveWorkoutView` fetches the completed-workouts list once and passes it to batched prefill calls. Lives in `ChartDataService.swift`.
- **WorkoutSyncService**: `@MainActor @Observable` class handling device→server workout sync. Uploads completed workouts via `POST /api/workouts` (idempotent, deduped by `local_id`). Tracks synced workout IDs in UserDefaults (`syncedWorkoutIds`). Bulk sync on launch via `syncAllPending(context:)`, per-workout sync on finish via `WorkoutSessionManager.syncService`. Profile shows sync status (pending count vs backed up). Backend stores workouts in MongoDB `workouts` collection with embedded exercises/sets; exercises deduped in `exercises` collection. Edit sync: `markWorkoutEdited()` + `updateWorkout()` sends `PUT /api/workouts/{local_id}` on WorkoutEditView dismiss. Delete sync: `markWorkoutDeleted()` + `deleteWorkoutFromServer()` sends `DELETE /api/workouts/{local_id}` on HistoryListView delete. Pending edits/deletes tracked in UserDefaults (`pendingEditWorkoutIds`, `pendingDeleteWorkoutIds`) and retried in `syncAllPending()`. Delete supersedes edit (deduplication). On launch, `syncAllPending` reconciles with server via `GET /api/workouts/ids`: rebuilds `syncedWorkoutIds` from server truth, deletes server-side orphans (workouts on server but not on device), uploads missing workouts. Client-authoritative — device state always wins.
- **AuthService**: `@MainActor @Observable` class managing authentication state. Stores API key in iOS Keychain via `KeychainService`, caches user profile in UserDefaults. Auth gate in `KilnApp.swift` conditionally renders `LoginView` or `ContentView`. On launch, checks Keychain for stored key and silently validates with backend; falls back to cached profile if offline. Per-user API keys replace the shared build-time `TIMER_BACKEND_API_KEY`.
- **KeychainService**: `enum` with static methods (`save`/`load`/`delete`) wrapping Security framework. Service name `app.izaro.kiln`, account-based key lookup.
- **LoginView**: Branded splash/login screen with fire light theme (grain background, flame icon, API key text field, Connect button). Shown when no valid API key is stored.
- **SwiftData @Model** objects bound directly to views via `@Bindable` and `@Query` — no classical ViewModel layer. `@Bindable` field edits funnel through `WorkoutSessionManager.handleSetValueChange(...)` which schedules a debounced save and syncs Live Activity state when the edited set is the current one.
- **TabView** with `selection` binding and `.tag()` — 4 tabs: Workouts (0), History (1), Exercises (2), Profile (3). Supports deep link tab switching from Live Activity via `onOpenURL`.
- **Exercise History Browser**: `ExerciseListView` shows all exercises alphabetically via `@Query(sort: \Exercise.name)` with `.searchable()` filtering. `ExerciseHistoryView` queries all finished workouts and filters in-memory by `exercise.id` (UUID) to find matching `WorkoutExercise` entries — avoids SwiftData `#Predicate` limitations with relationship traversal. Displays workout session cards with equipment-type-aware set formatting (mirrors `WorkoutDetailView.setDetailLabel` logic).
- **Rest timer**: inline below completed set (auto-hides when done), `Date` end-time in UserDefaults + wall-clock-derived foreground countdown; `lastCompletedSetId` on `WorkoutSessionManager` tracks placement. Display timer uses `RunLoop.common` mode so countdown updates during scroll. Local notification via `UNUserNotificationCenter` guarantees alert fires even when app is killed/backgrounded. **Skips on last set of an exercise** — both in-app (`completeSet`) and lock screen (`completeCurrentSetFromIntent`) paths check if all sets in the exercise are now completed and bypass timer/notification/backend scheduling if so.
- **NotificationService**: `@MainActor @Observable` class conforming to `UNUserNotificationCenterDelegate`. Schedules `UNTimeIntervalNotificationTrigger` with the user-selected alert sound on set completion; cancels on skip/finish/discard. Foreground delegate (`willPresent`) returns `[.sound]` so the notification plays its custom sound in foreground too (banner suppressed, user is already looking at the active workout UI). This single code path handles sound across foreground, background, and locked states. Permission requested on app launch.
- **AlertSoundService**: `@MainActor @Observable` class managing alert sound preference. Persists selection in UserDefaults key `selectedAlertSound`. Bundles 5 CAF files in `Kiln/Resources/`: `alert_tone.caf` (Default), `Spark.caf`, `Ember.caf`, `Kindle.caf`, `Blaze.caf`. Exposes `preview(_:)` for tap-to-hear in ProfileView picker. `NotificationService.scheduleRestTimer()` reads the user default and builds `UNNotificationSound(named:)` with the selected filename, falling back to `alert_tone.caf` if missing.
- **Live Activity**: Lock screen widget for completing entire workout without unlocking. Three views: `SetView` (adjustable weight/reps + Complete button), `TimerView` (countdown + Skip button + next set preview), `CompleteView` (all sets done). Interactive buttons via `LiveActivityIntent` (runs in app process). TimerView shows "Next:" preview with weight/reps of upcoming set; includes exercise name when crossing exercise boundaries (detected via `setNumber == 1`).
- **LiveActivityCache**: `enum` with static methods backed by App Group UserDefaults. Intent handlers read/write cached `ContentState` (zero SwiftData access — even in-memory reads trigger FaceID on lock screen). Cache keys: `la.state` (JSON-encoded ContentState), `la.setId`, `la.restDuration`, `la.dirty`, `la.dirtySetId`, `la.completedSetIds`, `la.pushToken`. Push token persisted so it survives app kill — `reconnectLiveActivity()` restores it immediately since `activity.pushTokenUpdates` only emits on fresh activity creation, not reconnection. Pending completions applied to in-memory model on timer expiry (`applyPendingCompletionsInMemory`). Foreground resume syncs cache → SwiftData via `syncCacheToSwiftData()`.
- **Intent split pattern**: Shared struct declarations in `Kiln/Shared/`, app-target `perform()` with real logic in `Kiln/Intents/`, widget-target stubs in `KilnWidgets/`. Widget extension cannot access SwiftData.
- **Template diff & update**: `TemplateDiff` struct compares workout exercises vs template exercises by `Exercise.id` (added/removed/moved counts). End-workout overlay conditionally shows "Finish & Update Template" button when exercises differ from the source template. `finishAndUpdateTemplate(context:)` replaces all `TemplateExercise` objects on the template with the workout's current exercise list.
- **Exercise reorder**: `ExerciseReorderView` provides drag-and-drop reordering of exercises during an active workout via a sheet.
- **Celebration screen**: `CelebrationData` struct snapshots workout stats (volume, sets, reps, distance, duration, workout count ordinal) at finish time. `CelebrationView` presented as `.fullScreenCover` on `ContentView` via `sessionManager.celebrationData`. Adaptive stat display uses `EquipmentType.tracksWeight/tracksReps/tracksDistance`. Ember particle animation via SwiftUI `Canvas` + `TimelineView`.
- **Notes on workouts and exercises**: `Exercise.notes` is shared across every workout that uses the exercise; `Workout.notes` is per-instance. `NotesSection` (inline display + pencil button → sheet with `TextEditor`) is wired into `ActiveWorkoutView` header (workout notes), `ExerciseCardView` (exercise notes, in-active-workout), and `ExerciseHistoryView` (exercise notes, Exercises tab). On `startWorkout(from:template:)`, workout notes are carried forward from the most recent completed workout with the same `templateId` so the prior message to future-self is pre-filled. Notes flow into the sync payload (`notes` at workout level, `exercise_notes` at exercise level) and are persisted to MongoDB (`workouts.notes`, `workouts.exercises[].exercise_notes`, `exercises.notes`). Exercise-note edits outside an active workout call `WorkoutSyncService.syncExerciseMetadataChange(for:in:)`, which re-uploads the most recent synced workout that uses the exercise so the server's `exercises` collection picks up the change. Notes are intentionally NOT displayed in `WorkoutDetailView` history.
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
│                                  #   (Exercise and Workout both carry an optional `notes: String?`)
├── Views/
│   ├── LoginView.swift             # API key login screen (shown when unauthenticated)
│   ├── ContentView.swift          # 4-tab TabView with conditional Workout tab
│   ├── DetailedSetLabelView.swift # App-only set label UI (must stay out of Shared/)
│   ├── NotesSection.swift         # Reusable inline notes display + NotesEditorSheet (TextEditor sheet)
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
│                                  #   LiveActivityCache, NotificationService, AlertSoundService,
│                                  #   TimerBackendService, CSVImportService, PreFillService,
│                                  #   AuthService, KeychainService, WorkoutSyncService
├── Shared/                        # WorkoutActivityAttributes, WorkoutLiveActivityIntents (shared with widget)
├── Intents/                       # WorkoutLiveActivityIntents+App (perform() bodies)
├── Assets.xcassets/               # App icon + body part icons + brick_icon + noise_tile
└── Design/                        # DesignSystem (colors, shadows, grain, corner radius, typography, spacing, icons)

timer-backend/
├── main.py              # FastAPI app: /api/me, /api/timer/schedule, /api/timer/cancel, /api/workouts (POST/PUT/DELETE), /api/workouts/status, /api/workouts/ids, /api/sync-glade, /api/backup, /health
├── backup.py            # Daily Google Drive backup: async gzipped JSON dump of all MongoDB collections, uploaded to a Drive folder with configurable retention. Scheduled nightly at 00:00 UTC from main.py lifespan; manual trigger via POST /api/backup. Sync Google API client calls offloaded via asyncio.to_thread. Env: GOOGLE_CLIENT_ID/SECRET/REFRESH_TOKEN, BACKUP_DATABASES (default "kiln"), BACKUP_DRIVE_FOLDER (default "kiln-backups"), BACKUP_RETENTION_DAYS (default 30). Disabled when creds are blank. OAuth client can be shared with Glade's Drive app — drive.file scope is per-file so folders stay isolated.
├── glade_sync.py        # Glade exercise sync: backfill on startup, inline sync on create/update/delete, fire-and-forget via httpx
├── models.py            # Pydantic models for workout sync payloads (WorkoutPayload, WorkoutResponse, SyncStatusResponse)
├── db.py                # MongoDB client (motor), user seeding (names via SEED_USER_NAMES env var), ensure_indexes(), get_db() helper
├── seed_demo.py         # Script to seed a demo user + sample workouts (split approach: mongosh for user, API for workouts)
├── apns.py              # APNSClient: ES256 JWT signing, HTTP/2 push to APNS
├── Dockerfile           # Multi-stage Python 3.12 + uv build for Coolify
├── pyproject.toml       # Dependencies managed by uv
└── .env.example         # APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH or APNS_KEY_BASE64, MONGODB_URL, APNS_ENVIRONMENT, SEED_USER_NAMES, GLADE_*

scripts/
├── frame_screenshots.py           # Adds iPhone device frames to PNG screenshots (Pillow)
└── generate_banner.py             # Generates README banner with app icon, grain texture, title (Pillow + numpy)

screenshots/                       # Framed screenshots + banner for README (committed, gitignore exception)

KilnWidgets/
├── KilnWidgetBundle.swift         # @main WidgetBundle + ActivityConfiguration
├── Views/                         # SetView, TimerView, CompleteView (lock screen presentations),
│                                  #   SetSummariesFlow (wrapping space-around Layout for the set row)
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
- **Local notifications for rest timer**: `NotificationService` schedules a `UNTimeIntervalNotificationTrigger` with the user-selected custom sound when a set is completed. Fires reliably across foreground (via `willPresent` returning `[.sound]`), background, and killed states — single code path for the alert sound regardless of app state.
- **Timer backend**: `timer-backend/` is a FastAPI microservice deployed on Coolify. Accepts timer schedule requests, sleeps for the duration, then sends APNS push-to-update to transition the Live Activity from timer view to next set view. In-memory timers + MongoDB for user profiles. Per-user API key auth (keys stored in `users` collection). Backend URL provided via `Secrets.xcconfig` → Info.plist → `Bundle.main`. API contracts in `specs/006-hybrid-timer-backend/contracts/timer-api.md` and `specs/007-user-auth/contracts/auth-api.md`.
- **TimerBackendService**: `@MainActor` HTTP client in `Kiln/Services/TimerBackendService.swift`. Reads `TimerBackendURL` from Info.plist and API key from Keychain. Fire-and-forget `scheduleTimer()` and `cancelTimer()` calls. Called from `WorkoutSessionManager` on set completion (schedule) and skip/finish/discard (cancel).
- **Glade exercise sync**: `glade_sync.py` pushes completed workouts to Glade (external personal data aggregation system) via its REST API. Configured via env vars (`GLADE_API_URL`, `GLADE_API_KEY`, `GLADE_CF_CLIENT_ID`, `GLADE_CF_CLIENT_SECRET`, `GLADE_SYNC_USER`). Only syncs workouts for the configured user with `started_at >= 2026-03-16`. Backfills all eligible workouts on server startup (dedup-safe via `source_id`). Inline sync on `POST /api/workouts` (create), `PUT /api/workouts/{local_id}` (update with PUT-then-POST fallback), `DELETE /api/workouts/{local_id}` (delete). All Glade calls are fire-and-forget `asyncio.create_task` — failures are logged but never block Kiln operations. Manual trigger via `POST /api/sync-glade`. Disabled when env vars are blank.
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
