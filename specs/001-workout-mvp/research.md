# Research: Workout MVP

**Branch**: `001-workout-mvp` | **Date**: 2026-02-22

## Decision 1: Persistence Framework — SwiftData

**Decision**: Use SwiftData (not Core Data) for all local persistence.

**Rationale**:
- iOS 17+ target with no legacy code — SwiftData is the idiomatic choice.
- `@Model` + `@Relationship` maps directly to our Workout → WorkoutExercise
  → Set hierarchy with cascade deletes.
- `@Query` and `@Bindable` integrate natively with SwiftUI views, eliminating
  boilerplate ViewModel layers for data display and editing.
- Supports immediate write-through via explicit `modelContext.save()` or
  `transaction {}` — critical for zero data loss on set completion.
- 1,734 rows of imported data is well within comfortable range.

**Alternatives considered**:
- **Core Data**: Battle-tested, supports batch operations and
  NSFetchedResultsController. Rejected because: no legacy code, no iCloud
  sync requirement, and SwiftData's simpler API reduces development time
  significantly for a single-user app.
- **SQLite directly (GRDB/SQLite.swift)**: Maximum control. Rejected because:
  unnecessary complexity for this data size, and loses SwiftUI integration
  benefits.

**Key constraints**:
- Autosave MUST be disabled. Explicit `save()` calls after every set
  completion to guarantee deterministic persistence.
- CSV import MUST run on a `@ModelActor` background actor with batched
  saves (batches of ~500) to avoid UI blocking.
- Use `relationshipKeyPathsForPrefetching` on FetchDescriptors to avoid
  N+1 queries when loading workouts with exercises and sets.

## Decision 2: Background Timer Strategy — Local Notifications + Timestamp

**Decision**: Use UNUserNotificationCenter for background alerts, combined
with a persisted `Date` end-time for accurate countdown display.

**Rationale**:
- Local notifications are system-level events owned by SpringBoard — they
  fire regardless of whether the app is running, backgrounded, or terminated.
- Persisting the timer end `Date` to UserDefaults survives app termination
  and allows accurate countdown recalculation on relaunch.
- The foreground countdown derives remaining time from `Date.now` vs. the
  stored end date on every tick — never holds a running counter in memory.

**Alternatives considered**:
- **BGTaskScheduler**: Designed for deferred maintenance tasks, not
  time-critical alerts. No guaranteed fire time. Rejected.
- **Timer + beginBackgroundTask**: Background task extension is ~30 seconds
  max, not enough for a 90-second rest timer. Rejected.
- **AVAudioSession (silent audio)**: Playing silent audio to prevent
  suspension is a known App Store rejection risk. Rejected.
- **AlarmKit**: Requires iOS 26. Not available on our iOS 17+ target.
  Rejected.

**Key constraints**:
- Use `UNNotificationSound.default` (not `.defaultCritical` which requires
  Apple entitlement approval).
- Cancel pending notification when timer is stopped early or a new set is
  completed before the timer expires.
- On scenePhase change to `.active`, call `syncFromPersistedState()` to
  recalculate the display countdown from the persisted end date.
- In-app foreground alert uses `UINotificationFeedbackGenerator` + system
  sound for haptic + audio when the user is actively using the app.

## Decision 3: App Architecture — @Observable + SwiftData Direct Binding

**Decision**: Use `@Observable` classes for behavioral/session state,
SwiftData `@Model` objects bound directly to views via `@Bindable` and
`@Query`. No classical MVVM ViewModel layer.

**Rationale**:
- SwiftData `@Model` objects already participate in SwiftUI's observation
  system. Adding ViewModels to relay data adds boilerplate without benefit.
- `@Observable` class (`WorkoutSessionManager`) manages non-persistent
  state: active workout reference, rest timer, workout elapsed time.
- The session manager is owned by the `App` struct via `@State` and injected
  via `.environment()`, surviving all tab switches naturally.
- `@Bindable` on `@Model` objects enables direct inline editing of set
  weight/reps without any intermediary.

**Alternatives considered**:
- **Classical MVVM (ObservableObject + @Published + Combine)**: Legacy
  pattern. Rejected because `@Observable` macro replaces it entirely for
  iOS 17+ with less boilerplate and better performance (fine-grained
  observation).
- **Singleton session manager**: Works but makes SwiftUI Previews and
  testing difficult. Rejected in favor of `@State` + `.environment()`.
- **TCA / Redux-style**: Massive overhead for a single-user app with 3
  screens. Rejected.

**Key patterns**:
- `TabView` with conditional `if/else` inside the Workout tab — shows
  `StartWorkoutView` or `ActiveWorkoutView` based on
  `sessionManager.isWorkoutInProgress`.
- `@Query` in list views for History and Profile (workouts-per-week
  aggregation as computed property on query results).
- Swift Charts `BarMark` for the workouts-per-week chart, driven by
  `@Query` data aggregated by ISO week.

## Decision 4: CSV Import Strategy

**Decision**: Parse Strong CSV using Swift's built-in string processing on
a `@ModelActor` background actor with batched SwiftData inserts.

**Rationale**:
- The Strong CSV is a simple format (10 columns, comma-delimited, quoted
  strings). No external CSV library is needed.
- Rows are grouped by (Date + Workout Name) to construct Workout entities,
  then by Exercise Name to construct WorkoutExercise entities, then
  individual Set entities.
- Exercise type (strength/cardio/bodyweight) is inferred from the data:
  if distance > 0 and seconds > 0 → cardio; if weight > 0 → strength;
  if weight = 0 and distance = 0 → bodyweight.
- Templates for "New Legs/full Body A" and "New Legs/full Body B" are
  auto-created from the most recent occurrence of each.

**Key constraints**:
- Import runs on a background actor to avoid blocking the UI.
- Saves in batches of ~500 rows to keep memory usage bounded.
- Invalid rows are skipped and counted; a summary is shown after import.
- Duration strings (e.g., "1h 16m", "45m") must be parsed to seconds.

## Decision 5: Weight Unit System

**Decision**: Display all weights in pounds (lb). No unit conversion needed.

**Rationale**:
- Single-user app. Isabel's Strong data is in lbs (confirmed by screenshot
  showing "77 lb", "90 lb" etc.).
- Adding unit conversion adds UI complexity with zero user benefit.
- Can be added later if needed.
