# Research: Live Activity Lock Screen Workout

**Feature**: 003-live-activity
**Date**: 2026-03-01

## R1: ActivityKit Architecture for Lock Screen Live Activities

**Decision**: Use ActivityKit with `ActivityAttributes` (static data) + nested `ContentState` (dynamic data) to power the lock screen live activity.

**Rationale**: ActivityKit is the only Apple-sanctioned way to display persistent, interactive content on the lock screen. The `ContentState` pattern allows efficient updates — only the changed dynamic data is sent, and the system handles rendering.

**Key findings**:
- `ActivityAttributes` holds immutable data set at activity start (workout name, workout start time)
- `ContentState` holds mutable data updated via `Activity.update()` (current exercise, weight, reps, timer state, etc.)
- ContentState has a **4 KB size limit** — must keep payload lean
- Live Activities can last up to **12 hours** on lock screen (sufficient for any workout)
- Local `Activity.update()` only fires when data actually changes (not per-second for timers)

**Alternatives considered**:
- Push-based updates via APNs: Overkill for a local-first app with no server involvement in workout flow
- WidgetKit timeline-based widgets: Cannot show real-time countdown timers or accept button interactions

---

## R2: Interactive Buttons on Lock Screen (iOS 17+ App Intents)

**Decision**: Use `Button(intent:)` with `LiveActivityIntent` conformance for all lock screen interactions (+/−, Complete, Skip).

**Rationale**: iOS 17 introduced interactive controls in Live Activities via App Intents. `LiveActivityIntent` is the specific protocol that ensures button taps execute in the main app process (when available), giving full access to SwiftData and WorkoutSessionManager.

**Key findings**:
- Regular `Button { closure }` does nothing in widget context — must use `Button(intent:)`
- Intent structs must be defined in a file shared by both the app and widget extension targets
- The `perform()` implementation must be split: real logic in the app target, stub in the widget target
- `LiveActivityIntent.perform()` runs in the **main app process** if the app is in memory; otherwise in the widget extension process (stubs handle this gracefully)
- `openAppWhenRun: Bool = false` keeps the app in the background — user stays on lock screen
- Tapping the Live Activity itself (not a button) opens the app via `widgetURL(_:)`

**Alternatives considered**:
- Darwin notifications (CFNotificationCenter) for cross-process signaling: More complex, less reliable, and unnecessary given LiveActivityIntent's app-process execution
- URL schemes to trigger actions: Opens the app (breaks lock screen workflow), no background execution

---

## R3: Timer Display on Lock Screen

**Decision**: Use `Text(timerInterval:countsDown:)` for the rest timer countdown, storing absolute `Date` end time in ContentState.

**Rationale**: This is ActivityKit's built-in timer rendering — the system updates the displayed time every second automatically without any `Activity.update()` calls. This avoids exhausting the update budget and eliminates timing drift.

**Key findings**:
- Store `timerEndDate: Date` in ContentState (absolute wall-clock time)
- `Text(timerInterval: Date.now...endDate, countsDown: true)` renders a live countdown
- Only need to call `Activity.update()` when the end date actually changes (e.g., user taps +/- or timer is skipped)
- When timer expires, the text shows "0:00" — the app must detect expiry and update ContentState to transition to the next set
- Consistent with existing RestTimerService which already stores `endDate` in UserDefaults

**Alternatives considered**:
- Updating ContentState every second with new `remainingSeconds`: Would exhaust update budget, cause visual lag, and waste battery
- Using a `ProgressView` with timer: Not supported in Live Activities

---

## R4: Widget Extension Target Structure

**Decision**: Create a `KilnWidgets` widget extension target via xcodegen `project.yml`, containing the `WidgetBundle`, Live Activity views, and intent stubs.

**Rationale**: ActivityKit requires a Widget Extension target — Live Activities cannot be defined in the main app target. The existing xcodegen workflow means we add the target in `project.yml` and regenerate.

**Key findings**:
- Widget extension is a separate process with its own sandbox
- Cannot access SwiftData, main app UserDefaults, or Keychain directly
- All display data must flow through `ActivityAttributes` / `ContentState`
- App Groups (`group.com.isabelgwara.Kiln`) needed for shared UserDefaults (rest timer persistence, supplemental data)
- `NSSupportsLiveActivities: true` required in main app Info.plist
- Dynamic Island closures are required by `ActivityConfiguration` API even on iPhone 13 — provide minimal stubs
- Image assets used in the Live Activity must be in the widget extension's asset catalog
- `.contentMarginsDisabled()` (iOS 17+) removes default widget padding for full-bleed design

**Alternatives considered**:
- Shared Swift Package for common types: Premature complexity for single-user app; target membership (adding files to both targets) is simpler

---

## R5: Data Synchronization Between App and Live Activity

**Decision**: All display data flows through ContentState. The app calls `Activity.update()` after every state change (set complete, weight/reps adjust, timer start/stop/skip, exercise advance). The widget extension is purely a rendering surface.

**Rationale**: ContentState is the single source of truth for what the Live Activity displays. Since the widget extension can't access SwiftData, and all interactive buttons execute via LiveActivityIntent in the main app process, the data flow is unidirectional: SwiftData → WorkoutSessionManager → ContentState → Live Activity UI.

**Key findings**:
- ContentState must include: exercise name, set number, total sets in exercise, weight/reps/duration/distance values, previous set display string, equipment type indicator, timer end date, timer active flag, workout start time (for elapsed), workout complete flag
- The 4 KB ContentState limit is easily met — a typical state is ~200 bytes
- `AlertConfiguration(sound: .default)` on `Activity.update()` plays a sound when the timer expires
- App Groups shared UserDefaults serves as a backup channel for rest timer state (crash recovery)

**Alternatives considered**:
- Having the widget extension read directly from shared SwiftData store: Not supported by Apple — SwiftData contexts in widget extensions have known reliability issues and can't observe changes in real time

---

## R6: Sound Alert on Timer Expiry

**Decision**: Use `AlertConfiguration(sound: .default)` when updating the Live Activity at timer expiry. This plays the system notification sound and presents the Live Activity as a banner.

**Rationale**: This is the official ActivityKit mechanism for alerting the user when a Live Activity's state changes significantly. It works even when the phone is locked.

**Key findings**:
- `AlertConfiguration` is passed to `Activity.update()` as an optional parameter
- Supports `.default` system sound or `.named("custom_sound.aiff")` for bundled custom sounds
- Plays even when the phone is locked (same behavior as notification sounds)
- Subject to Do Not Disturb / Focus mode settings (same as existing notification behavior)
- The existing `UNUserNotificationCenter` notification in RestTimerService can be kept as a fallback for when the app is terminated

**Alternatives considered**:
- Only using UNUserNotificationCenter: Would show a separate notification banner instead of updating the Live Activity in-place; less cohesive UX
- Playing sound from the app directly (AVAudioSession): Requires the app to be in the foreground

---

## R7: Set Progression Logic

**Decision**: Introduce a `SetProgressionService` (or method on WorkoutSessionManager) that computes the "current set" — the next incomplete set in workout order — by iterating exercises then sets within each exercise.

**Rationale**: The lock screen needs to always show the correct "next set to complete." This requires a deterministic ordering algorithm that matches the in-app exercise/set display order.

**Key findings**:
- Exercises are ordered by `WorkoutExercise.order`
- Sets within each exercise are ordered by `WorkoutSet.order`
- "Current set" = first set where `isCompleted == false`, scanning exercises in order
- When all sets are complete, transition to "workout complete" state
- The current set's exercise determines which exercise name to display
- Previous set data comes from PreFillService (already computed at workout start and stored as pre-fill values)
- Need to also track: total incomplete sets remaining, current set index within its exercise

**Alternatives considered**:
- Storing current set index explicitly: Fragile if sets are added/deleted from the app during the workout; scanning for first incomplete set is more robust
