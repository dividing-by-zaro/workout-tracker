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

**Things to investigate:**

- Is `Activity.update()` itself the bottleneck? iOS may throttle rapid updates.
- Cache current set weight/reps in `UserDefaults` (App Group `group.app.izaro.kiln`) so intents can read/write without traversing SwiftData. Only sync back on set completion / foreground resume. This removes `findCurrentSet()` + `buildContentState()` model graph traversals from the hot path.
- Profile the intent execution time to identify which step is slowest.

### Bug 2: FaceID required to complete a set

**Status:** Open

Tapping the "Complete" button on the lock screen Live Activity prompts FaceID authentication. Adjusting weight/reps may also require it.

**Root cause:** SwiftData's backing SQLite store uses `NSFileProtectionComplete` by default. The database is encrypted and inaccessible when the device is locked. When a `LiveActivityIntent` tries to read/write SwiftData objects, iOS forces FaceID to unlock the file.

**What we tried:**

Set `NSFileProtectionCompleteUntilFirstUserAuthentication` on the Application Support directory and existing store file in `KilnApp.init()`. This should make data accessible after the first device unlock of the day.

```swift
// In KilnApp.init()
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
let protection = FileProtectionType.completeUntilFirstUserAuthentication
try? FileManager.default.setAttributes([.protectionKey: protection], ofItemAtPath: appSupport.path)
let storeFile = appSupport.appendingPathComponent("default.store")
if FileManager.default.fileExists(atPath: storeFile.path) {
    try? FileManager.default.setAttributes([.protectionKey: protection], ofItemAtPath: storeFile.path)
}
```

**Result:** Still requires FaceID.

**Things to investigate:**

- The store file may not be at `default.store` — check the actual SwiftData store path. Print `ModelConfiguration().url` to find it.
- Setting attributes on the directory may not retroactively change existing files' protection class. May need to set it on every file in the store directory (`.store`, `.store-shm`, `.store-wal`).
- SwiftData may use a custom store location, not Application Support. Need to verify.
- Alternative: create a `ModelConfiguration` with an explicit URL in a directory with the correct protection set before any files are created.
- Alternative: bypass SwiftData entirely for lock screen intents — cache the active set data in `UserDefaults` (App Group) and only sync to SwiftData when the app is in foreground. This would fix both the FaceID issue and the lag issue simultaneously.
- Check if the app needs to be deleted and reinstalled for file protection changes to take effect on already-created store files.

### Non-issue: Screen timeout not reset by button taps

Tapping Live Activity buttons doesn't reset the screen auto-lock timer (e.g., screen stays on for 5s, tap at 1s, still turns off at 4s). This is an iOS system-level behavior — Live Activity button taps aren't treated as user interaction for the idle timer. No app-side workaround exists.

### Changes currently in the codebase

| File | Change |
|------|--------|
| `Kiln/Resources/silence.caf` | 1-second quiet 100Hz sine wave (~0.3% amplitude) for background audio |
| `Kiln/Services/BackgroundAudioService.swift` | New `@Observable` service: `AVAudioSession` `.playback` + `.mixWithOthers`, plays `silence.caf` on loop at volume 0.01 |
| `project.yml` | `UIBackgroundModes: [audio]`, `Kiln/Resources` in resources, `Resources` excluded from sources |
| `Kiln/Info.plist` | `audio` in `UIBackgroundModes` array |
| `Kiln/Services/WorkoutSessionManager.swift` | Background audio starts at workout start, stops at workout end. `context.save()` removed from adjust intents. Foreground resume flushes unsaved changes and restarts audio if needed. |
| `Kiln/Intents/WorkoutLiveActivityIntents+App.swift` | `CompleteSetIntent.perform()` simplified — removed `Task.sleep` hack |
| `Kiln/KilnApp.swift` | `init()` attempts to set `NSFileProtectionCompleteUntilFirstUserAuthentication` on store directory (not working yet) |
