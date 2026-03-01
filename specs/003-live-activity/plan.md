# Implementation Plan: Live Activity Lock Screen Workout

**Branch**: `003-live-activity` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-live-activity/spec.md`

## Summary

Add a lock screen Live Activity (ActivityKit) that lets users complete their entire workout without unlocking the phone. The Live Activity shows the current exercise, previous set data, weight/reps with +/- buttons, and a Complete button. After completing a set, a countdown rest timer appears. When the timer expires, a sound plays and the next set is shown. The Live Activity is created automatically when a workout starts and removed when it finishes. Target device: iPhone 13 (no Dynamic Island).

## Technical Context

**Language/Version**: Swift 5.9+ / SwiftUI
**Primary Dependencies**: ActivityKit, WidgetKit, AppIntents (LiveActivityIntent)
**Storage**: SwiftData (existing, main app only) + App Groups shared UserDefaults (widget ↔ app)
**Testing**: Manual on-device testing (Live Activities require physical iPhone 13)
**Target Platform**: iOS 17+ / iPhone 13 & iPhone 13 mini only
**Project Type**: Mobile app (iOS) — adding widget extension target
**Performance Goals**: ContentState updates within 100ms of user action; timer countdown at 1-second accuracy
**Constraints**: 4 KB ContentState size limit; no Dynamic Island; no network access from widget extension; widget extension cannot access SwiftData
**Scale/Scope**: Single user, single active workout at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Zero Data Loss | PASS | Set completion from Live Activity executes via LiveActivityIntent in main app process → SwiftData save with explicit context.save(). Same write-through pattern as in-app completion. Crash recovery: Live Activity persists independently; app reconnects on relaunch. |
| II. Minimal Friction | PASS | Core value of this feature — completing a set requires one tap from lock screen. No unlock, no app navigation. Weight/reps adjustable in-place. |
| III. Timer Reliability | PASS | Rest timer uses Text(timerInterval:countsDown:) for lock screen display (system-rendered, no drift). Existing UNNotification scheduling preserved as fallback. AlertConfiguration plays sound on timer expiry. Timer state persisted in UserDefaults (existing pattern) + App Groups for widget access. |
| IV. Live Activity First | PASS | This feature directly implements Principle IV. Lock screen only (no Dynamic Island for iPhone 13). Interactive buttons via LiveActivityIntent. Set completion, weight/reps adjustment, timer skip all available on lock screen. |
| V. Beautiful & Joyful Design | PASS | Live Activity uses DesignSystem color tokens (fire red primary, warm cream background). Consistent typography. Clean layout adapts to equipment type. |
| VI. Single-User Simplicity | PASS | No multi-user impact. Single active workout = single Live Activity. No auth changes. |
| VII. Data Portability | N/A | No impact on import/export. |

**Post-Phase 1 re-check**: All gates still pass. Data model keeps ContentState lean (~250 bytes). Intent pattern ensures main-app-process execution for SwiftData writes. No new persistence layer introduced — reuses existing SwiftData + UserDefaults.

## Project Structure

### Documentation (this feature)

```text
specs/003-live-activity/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: ActivityKit research & decisions
├── data-model.md        # Phase 1: ActivityAttributes, ContentState, intents
├── quickstart.md        # Phase 1: Setup & testing guide
├── contracts/
│   └── live-activity-states.md  # UI contract: 3 lock screen states
└── tasks.md             # Phase 2 output (not yet created)
```

### Source Code (repository root)

```text
Kiln/
├── Shared/                                    # NEW — files added to BOTH targets
│   ├── WorkoutActivityAttributes.swift        # ActivityAttributes + ContentState structs
│   └── WorkoutLiveActivityIntents.swift       # Intent struct declarations (no perform bodies)
├── Services/
│   ├── WorkoutSessionManager.swift            # MODIFIED — live activity lifecycle + intent handlers
│   ├── RestTimerService.swift                 # MODIFIED — onTimerExpired callback
│   └── LiveActivityService.swift              # NEW — encapsulates Activity<> start/update/end
├── Intents/
│   └── WorkoutLiveActivityIntents+App.swift   # NEW — perform() implementations (app target only)
├── KilnApp.swift                              # MODIFIED — crash recovery for live activity
└── ...existing files unchanged...

KilnWidgets/                                   # NEW — widget extension target
├── KilnWidgetBundle.swift                     # @main WidgetBundle with ActivityConfiguration
├── Views/
│   ├── SetView.swift                          # Lock screen: exercise + weight/reps + complete button
│   ├── TimerView.swift                        # Lock screen: countdown + skip button
│   └── CompleteView.swift                     # Lock screen: "All sets complete" state
├── WorkoutLiveActivityIntents+Widget.swift    # Intent perform() stubs
├── Assets.xcassets/                           # Color tokens + icons for widget rendering
└── Info.plist                                 # NSExtension widget config

project.yml                                    # MODIFIED — add KilnWidgets target + App Groups
```

**Structure Decision**: The existing single-target iOS app structure is extended with one widget extension target (`KilnWidgets`). Shared code (ActivityAttributes, Intent declarations) lives in `Kiln/Shared/` with dual target membership rather than a Swift Package — appropriate for the project's single-user scale. The main app owns all business logic; the widget extension is purely a rendering surface with intent stubs.

## Complexity Tracking

No constitution violations to justify. The widget extension target is the minimum required by Apple's ActivityKit — it cannot be avoided.
