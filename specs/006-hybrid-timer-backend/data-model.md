# Data Model: Hybrid Rest Timer with Backend

## Existing Entities (unchanged)

These SwiftData models are unaffected by this feature:

- **Workout**, **WorkoutExercise**, **WorkoutSet** — workout data graph
- **Exercise**, **WorkoutTemplate**, **TemplateExercise** — exercise/template catalog
- **CelebrationData** — post-workout celebration stats

## Existing Entities (modified)

### WorkoutActivityAttributes.ContentState

No schema changes. The existing `ContentState` is already `Codable` and will be serialized as the APNS push payload's `content-state` field.

Fields used in push payload:
- `exerciseName: String`
- `setNumber: Int`
- `totalSetsInExercise: Int`
- `previousSetLabel: String`
- `weight: Double?`
- `reps: Int?`
- `duration: Double?`
- `distance: Double?`
- `equipmentCategory: String`
- `isRestTimerActive: Bool` (set to `false` in push — timer is done)
- `restTimerEndDate: Date` (set to `.distantPast` in push)
- `restTotalSeconds: Int` (set to `0` in push)
- `isWorkoutComplete: Bool`
- `exerciseIndex: Int`
- `totalExercises: Int`

## New Entities

### TimerScheduleRequest (backend API input)

Sent from the iOS app to the backend when a rest timer starts.

- `pushToken: String` — hex-encoded Live Activity push token
- `durationSeconds: Int` — seconds until timer expiry
- `contentState: Object` — JSON object matching ContentState schema (the next-set state to push on expiry)
- `deviceId: String` — stable device identifier for cancellation (e.g., `UIDevice.current.identifierForVendor`)

### TimerCancelRequest (backend API input)

Sent from the iOS app to the backend when a timer is skipped or workout ends.

- `deviceId: String` — matches the device that scheduled the timer

### PendingTimer (backend in-memory)

Internal to the backend service. Not persisted.

- `deviceId: String` — key for lookup/cancellation
- `pushToken: String` — APNS target
- `contentState: Object` — payload to send
- `fireAt: DateTime` — wall-clock time when the push should be sent
- `taskHandle: AsyncTask` — reference to the scheduled asyncio task (for cancellation)

## State Transitions

### Rest Timer Lifecycle

```
Set Completed
    │
    ├─→ RestTimerService.start(duration)     [persists endDate to UserDefaults]
    ├─→ Schedule local notification           [UNTimeIntervalNotificationTrigger]
    ├─→ POST /api/timer/schedule to backend   [sends pushToken + contentState]
    ├─→ Update Live Activity (timer view)     [isRestTimerActive = true]
    │
    ▼
Timer Running
    │
    ├─ [Skip pressed] ─→ RestTimerService.stop()
    │                  ─→ Cancel local notification
    │                  ─→ POST /api/timer/cancel to backend
    │                  ─→ Update Live Activity (next set view)
    │
    ├─ [Timer expires — app foreground]
    │  ─→ RestTimerService.tick() detects expiry
    │  ─→ Suppress local notification banner (delegate)
    │  ─→ Play alert_tone.caf via AVAudioPlayer
    │  ─→ Haptic feedback
    │  ─→ Update Live Activity (next set view)
    │
    ├─ [Timer expires — app backgrounded/locked]
    │  ─→ Local notification fires (SpringBoard)
    │  ─→ APNS push arrives → Live Activity transitions to next set
    │  ─→ On foreground resume: syncFromPersistedState() + syncCacheToSwiftData()
    │
    └─ [Timer expires — backend unreachable]
       ─→ Local notification fires (always)
       ─→ Live Activity stuck on timer view until foreground resume
       ─→ On foreground resume: handleTimerExpired() updates Live Activity
```
