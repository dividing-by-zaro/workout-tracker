# Research: Hybrid Rest Timer with Backend

## Decision 1: Backend Technology

**Decision**: Python + FastAPI + asyncio, deployed on Coolify via Dockerfile

**Rationale**:
- Constitution specifies Python (FastAPI) as the backend technology
- FastAPI's async support handles concurrent timer scheduling via `asyncio.create_task()` + `asyncio.sleep()`
- `PyJWT` + `cryptography` libraries provide APNS JWT signing (ES256)
- `httpx` provides async HTTP/2 client for APNS delivery
- User specified Coolify as hosting platform (constitution says Railway — this is a hosting-only deviation, not a technology deviation)

**Alternatives considered**:
- Go + net/http: Smallest Docker image (5-15MB vs ~200MB), goroutines ideal for timers, but not aligned with constitution
- Bun + HTTP server: Fast startup, small image, but `setTimeout()` is process-local and less mature for production scheduling
- Both alternatives rejected because constitution explicitly mandates Python/FastAPI

## Decision 2: APNS Live Activity Push-to-Update

**Decision**: Start Live Activity with `pushType: .token`, observe push token via `activity.pushTokenUpdates`, send token to backend for server-driven updates

**Rationale**:
- This is the only Apple-supported mechanism to update a Live Activity when the app is suspended
- Push tokens are per-Live Activity and may rotate — must observe the async sequence
- No widget extension code changes needed — ActivityKit automatically delivers push updates to the widget

**Key payload format**:
```json
{
  "aps": {
    "timestamp": 1685952000,
    "event": "update",
    "content-state": { ... matches ContentState schema ... },
    "alert": {
      "title": "Rest Complete",
      "body": "Time for your next set!",
      "sound": "alert_tone.caf"
    }
  }
}
```

**APNS headers**:
- `apns-push-type: liveactivity`
- `apns-topic: app.izaro.kiln.push-type.liveactivity`
- `apns-priority: 10` (time-critical)
- `authorization: bearer <JWT>`

**Rate limits**: iOS 17 allows ~1 update/second. iOS 18+ reduces to 5-15s intervals. Single update on timer expiry is well within limits.

## Decision 3: Local Notification Scheduling

**Decision**: Use `UNUserNotificationCenter` with `UNTimeIntervalNotificationTrigger` for reliable timer alerts

**Rationale**:
- Local notifications are owned by SpringBoard (iOS system process), not the app process
- Fire reliably when app is backgrounded, suspended, or force-quit
- Zero entitlements required (only runtime permission request)
- Custom sound supported via bundled `alert_tone.caf` (already in app bundle, CAF format, under 30s)

**Foreground handling**: Implement `UNUserNotificationCenterDelegate.willPresent` to suppress the system banner when the app is active, and instead play the alert via `AVAudioPlayer` directly (existing pattern)

## Decision 4: Alert Sound Strategy

**Decision**: Dual-path alert sound

**Rationale**:
- **Background/locked**: Local notification plays `alert_tone.caf` via `UNNotificationSound(named:)`
- **Foreground**: Suppress notification banner, play `alert_tone.caf` via `AVAudioPlayer` directly (existing `BackgroundAudioService.playAlertSound()` — this method survives even after removing the silent audio loop)
- **APNS push**: Include `alert.sound: "alert_tone.caf"` in push payload for additional lock screen alert

## Decision 5: Removing Silent Audio

**Decision**: Remove the silent audio loop from `BackgroundAudioService` but keep the `playAlertSound()` method

**Rationale**:
- Silent audio was a workaround to keep the app process alive for timer expiry — no longer needed
- `startSilentAudio()` / `stopSilentAudio()` methods and `silence.caf` can be removed
- `playAlertSound()` is still needed for foreground alert tone playback
- The `audio` background mode in Info.plist can be removed (or kept for foreground alert — needs testing)
- The `beginBackgroundTask` + `DispatchWorkItem` scheduling in `WorkoutSessionManager` can be removed

## Decision 6: Timer State Persistence on Backend

**Decision**: Stateless in-memory timers on backend (accept timer loss on restart)

**Rationale**:
- Timers are short-lived (30s–5min typically, max ~10min)
- If backend restarts during a timer, the local notification still fires (graceful degradation)
- Live Activity recovers on foreground resume via `syncFromPersistedState()`
- No database needed — keeps the service trivially simple
- Single-user app makes this even more acceptable (no concurrent timer storms)

## Decision 7: Backend Authentication

**Decision**: Single API key in request header, matching constitution pattern

**Rationale**:
- Constitution mandates "Single API key stored in iOS Keychain, entered once during initial setup"
- Backend validates `Authorization: Bearer <api-key>` on every request
- API key stored as environment variable on Coolify
- Simple, sufficient for single-user app

## Decision 8: Push Notification Entitlements

**Decision**: Add `aps-environment` entitlement and Push Notifications capability

**Rationale**:
- Required for APNS push delivery (Live Activity push-to-update)
- Not required for local notifications (those work without entitlements)
- Need to register bundle ID for push in Apple Developer portal
- Add `remote-notification` to `UIBackgroundModes` for push wake
