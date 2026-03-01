## Remaining Live Activity issues on real device

### What works

- Rest timer counts down correctly on the lock screen
- Sound plays and Live Activity advances to the next set when timer hits 0:00
- Background audio approach (`silence.caf` + `UIBackgroundModes: audio`) successfully keeps the app process alive

### Bug 1: Live Activity buttons are laggy

**Status:** Open

Tapping +/- weight/reps buttons on the lock screen Live Activity has noticeable delay before the UI updates. Each tap goes through: system routes intent → `MainActor.run` → modify in-memory model → `buildContentState()` (traverses SwiftData model graph) → `Activity.update()` (async system call) → iOS re-renders widget.

**What we tried:**

1. **Removed `context.save()` from adjust intents** — No more SQLite disk write per tap. In-memory model objects are updated immediately; data flushed on `handleForegroundResume()` and set completion. Helped but buttons are still laggy.

2. **Background audio runs for entire workout** — Originally started/stopped per rest period, meaning the app was suspended between rests and each tap required a full process wake-up (~100ms–1s). Changed to run from workout start to workout end. Should eliminate wake-up latency but buttons are still laggy.

3. **UserDefaults cache for intent handlers (LiveActivityCache)** — Created `LiveActivityCache` enum backed by App Group UserDefaults. Intent handlers now read/write cached `ContentState` JSON instead of traversing SwiftData. `adjustWeightFromIntent` / `adjustRepsFromIntent` call `LiveActivityCache.adjustWeight(delta:)` → `updateLiveActivity(with:)` with zero SwiftData access. `completeCurrentSetFromIntent` reads cached state, mutates timer fields, records completion ID for later sync. Foreground resume syncs cache → SwiftData via `syncCacheToSwiftData()`. **Result:** Still laggy on +/- buttons. The bottleneck is `Activity.update()` itself (async system round-trip to re-render the widget), not SwiftData or model traversal.

**Current understanding:**

The intent hot path is now: read UserDefaults → decode JSON → mutate struct → encode JSON → write UserDefaults → `Activity.update()`. The first 5 steps are microseconds. The remaining delay is the `Activity.update()` system call — iOS processes the update, re-renders the WidgetKit view, and pushes it to the lock screen. This is an iOS system-level constraint, not something we can optimize on the app side.

**Things to investigate:**

- iOS may throttle rapid Live Activity updates. Check if there's a minimum interval between `Activity.update()` calls.
- Profile the intent execution time end-to-end to confirm `Activity.update()` is the slow step.
- Consider whether the lag is acceptable given it's a system-level constraint, or if there's an alternative rendering approach.

### Bug 2: FaceID required to complete a set

**Status:** Fixed

**Root cause:** SwiftData's backing SQLite store uses `NSFileProtectionComplete` by default. The database is encrypted and inaccessible when the device is locked. When a `LiveActivityIntent` tries to read/write SwiftData objects, iOS forces FaceID to unlock the file.

**What we tried:**

1. Set `NSFileProtectionCompleteUntilFirstUserAuthentication` on the Application Support directory and store file in `KilnApp.init()`. **Result:** Still required FaceID.

2. **UserDefaults cache (LiveActivityCache)** — Bypassed SwiftData entirely for lock screen intents. All intent handlers now read/write from App Group UserDefaults. SwiftData is only touched on foreground resume. Removed the file protection hack from `KilnApp.init()`. **Result:** Still required FaceID to complete a set — `completeCurrentSetFromIntent()` had a trailing `findCurrentSet()` call that touched SwiftData.

3. **Removed `findCurrentSet()` from `completeCurrentSetFromIntent()`** — The "best effort" in-memory SwiftData mark was triggering FaceID. Moved that logic to `applyPendingCompletionsInMemory()`, called only from `handleTimerExpired()` and `skipRestTimerFromIntent()` (which run while the app is active in background, not from a lock screen intent). **Result:** Fixed — no FaceID prompt on Complete.

### Non-issue: Screen timeout not reset by button taps

Tapping Live Activity buttons doesn't reset the screen auto-lock timer (e.g., screen stays on for 5s, tap at 1s, still turns off at 4s). This is an iOS system-level behavior — Live Activity button taps aren't treated as user interaction for the idle timer. No app-side workaround exists.

### Changes currently in the codebase

| File | Change |
|------|--------|
| `Kiln/Resources/silence.caf` | 1-second quiet 100Hz sine wave (~0.3% amplitude) for background audio |
| `Kiln/Services/BackgroundAudioService.swift` | New `@Observable` service: `AVAudioSession` `.playback` + `.mixWithOthers`, plays `silence.caf` on loop at volume 0.01 |
| `Kiln/Services/LiveActivityCache.swift` | New `enum` with static methods: caches `ContentState` JSON + set ID + rest duration in App Group UserDefaults. Provides `adjustWeight(delta:)`, `adjustReps(delta:)`, `recordCompletion(setId:)`, `consumePendingSync()` |
| `project.yml` | `UIBackgroundModes: [audio]`, `Kiln/Resources` in resources, `Resources` excluded from sources |
| `Kiln/Info.plist` | `audio` in `UIBackgroundModes` array |
| `Kiln/Services/WorkoutSessionManager.swift` | Intent handlers rewritten to use `LiveActivityCache` (no SwiftData). `cacheCurrentState()` called after every app-side LA update. `syncCacheToSwiftData()` on foreground resume applies pending completions + dirty weight/reps. Background audio starts at workout start, stops at workout end. |
| `Kiln/Intents/WorkoutLiveActivityIntents+App.swift` | `CompleteSetIntent.perform()` simplified — removed `Task.sleep` hack |
| `Kiln/KilnApp.swift` | Removed file protection `init()` hack (no longer needed) |
