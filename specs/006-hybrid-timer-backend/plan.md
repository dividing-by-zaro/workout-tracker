# Implementation Plan: Hybrid Rest Timer with Backend

**Branch**: `006-hybrid-timer-backend` | **Date**: 2026-03-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-hybrid-timer-backend/spec.md`

## Summary

Replace the unreliable silent-audio + DispatchWorkItem timer mechanism with a hybrid approach: local notifications (UNUserNotificationCenter) for guaranteed alert delivery, and a Coolify-hosted FastAPI backend that sends APNS push-to-update Live Activities when the rest timer expires. This is the only approach that reliably solves both the alert sound and the Live Activity state transition problems.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS app), Python 3.12 (backend)
**Primary Dependencies**: SwiftUI, ActivityKit, UserNotifications (iOS); FastAPI, httpx, PyJWT (backend)
**Storage**: SwiftData (existing, unchanged); no database for backend (in-memory timers)
**Testing**: Manual Xcode testing (iOS); pytest (backend)
**Target Platform**: iOS 17+ (iPhone 13), Linux container on Coolify (backend)
**Project Type**: Mobile app + microservice
**Performance Goals**: Alert fires within 1s of expiry; Live Activity update within 3s
**Constraints**: Must work when app is backgrounded/locked/force-quit; graceful degradation without network
**Scale/Scope**: Single user, single device, one timer at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | No changes to SwiftData persistence. Set completions still save immediately. |
| II. Minimal Friction | PASS | No new user interactions. Notification permission is one-time auto-prompt. |
| III. Timer Reliability | PASS | This feature directly implements this principle. Local notifications + APNS push guarantee timer fires regardless of app state. |
| IV. Live Activity First | PASS | APNS push-to-update enables Live Activity transitions without app process. |
| V. Beautiful & Joyful Design | PASS | No UI changes to app views. Live Activity transitions become smoother. |
| VI. Single-User Simplicity | PASS | Single API key auth. No user tables. Backend is single-purpose. |
| VII. Data Portability | N/A | No data format changes. |

**Constitution deviation**: Backend hosted on Coolify instead of Railway (constitution says Railway). This is a hosting-only deviation — technology (Python/FastAPI) is unchanged. Justified because user has existing Coolify infrastructure.

**Post-Phase 1 re-check**: All gates still PASS. APNS push payload uses existing `ContentState` schema — no new data entities that could affect data portability.

## Project Structure

### Documentation (this feature)

```text
specs/006-hybrid-timer-backend/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── timer-api.md     # Backend API contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Kiln/
├── Services/
│   ├── WorkoutSessionManager.swift   # Modified: integrate notifications + backend calls
│   ├── RestTimerService.swift        # Modified: trigger notification schedule/cancel
│   ├── NotificationService.swift     # NEW: UNUserNotificationCenter wrapper
│   ├── TimerBackendService.swift     # NEW: HTTP client for backend API
│   ├── LiveActivityService.swift     # Modified: pushType: .token, push token observation
│   ├── BackgroundAudioService.swift  # Modified: remove silent audio, keep playAlertSound()
│   └── LiveActivityCache.swift       # Unchanged
├── KilnApp.swift                     # Modified: notification permission request, delegate setup
├── Kiln.entitlements                 # Modified: add aps-environment
└── Info.plist                        # Modified: add remote-notification background mode

timer-backend/
├── main.py              # FastAPI app: /timer/schedule, /timer/cancel
├── apns.py              # APNS JWT signing + HTTP/2 push delivery
├── Dockerfile           # Multi-stage Python 3.12 + uv build
├── pyproject.toml       # Dependencies (fastapi, uvicorn, httpx, pyjwt, cryptography)
└── .env.example         # Environment variable template

project.yml              # Modified: add remote-notification to UIBackgroundModes
```

**Structure Decision**: Mobile app + backend microservice pattern. The timer-backend is a new directory at repo root containing the Coolify-deployed FastAPI service. iOS app changes are in existing files with two new service classes.

## Complexity Tracking

| Deviation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Backend microservice | Only way to update Live Activity when app is suspended (APNS push-to-update requires a server) | No simpler alternative — Apple does not provide any client-side mechanism to update Live Activities from a suspended app |
| Coolify instead of Railway | User's existing infrastructure | Railway would work identically but adds another hosting provider |
