# Quickstart: Live Activity Lock Screen Workout

**Feature**: 003-live-activity
**Date**: 2026-03-01

## Prerequisites

- Xcode 15+ with iOS 17 SDK
- iPhone 13 or iPhone 13 mini (physical device required — Live Activities cannot be fully tested in Simulator)
- xcodegen installed (`brew install xcodegen`)
- Apple Developer account with provisioning profiles for both the app and widget extension targets

## Project Setup

### 1. Add Widget Extension Target

Update `project.yml` to add the `KilnWidgets` target:

```yaml
targets:
  Kiln:
    # ... existing config ...
    settings:
      base:
        # Add to existing settings:
        INFOPLIST_KEY_NSSupportsLiveActivities: YES
    entitlements:
      path: Kiln/Kiln.entitlements  # Add App Groups capability
    dependencies:
      - target: KilnWidgets
        embed: true

  KilnWidgets:
    type: app-extension
    platform: iOS
    sources:
      - path: KilnWidgets
      - path: Kiln/Shared  # Shared files (ActivityAttributes, Intent declarations)
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.isabelgwara.Kiln.KilnWidgets
        PRODUCT_NAME: KilnWidgets
        SWIFT_VERSION: "5.9"
    entitlements:
      path: KilnWidgets/KilnWidgets.entitlements  # Same App Groups
```

### 2. Regenerate Xcode Project

```bash
xcodegen generate
```

### 3. Configure Signing & Capabilities

In Xcode:
1. Select **Kiln** target → Signing & Capabilities → + Capability → **App Groups** → Add `group.com.isabelgwara.Kiln`
2. Select **KilnWidgets** target → same App Groups configuration
3. Ensure both targets have valid provisioning profiles

### 4. Directory Structure

```text
Kiln/
├── Shared/                              # NEW: Files in both targets
│   ├── WorkoutActivityAttributes.swift  # ActivityAttributes + ContentState
│   └── WorkoutLiveActivityIntents.swift # Intent struct declarations
├── Services/
│   ├── WorkoutSessionManager.swift      # MODIFIED: Add live activity methods
│   ├── RestTimerService.swift           # MODIFIED: Add onTimerExpired callback
│   ├── LiveActivityService.swift        # NEW: Activity lifecycle management
│   └── ...
├── Intents/
│   └── WorkoutLiveActivityIntents+App.swift  # NEW: Intent perform() bodies
└── ...

KilnWidgets/                             # NEW: Widget extension target
├── KilnWidgetBundle.swift               # @main entry point
├── WorkoutLiveActivityView.swift        # Lock screen SwiftUI views
├── WorkoutLiveActivityIntents+Widget.swift  # Intent perform() stubs
├── Assets.xcassets/                     # Widget-specific assets (colors)
└── Info.plist
```

## Testing on Device

### Basic Lifecycle Test
1. Build and run on iPhone 13
2. Start a workout from a template
3. Lock the phone → verify Live Activity appears on lock screen
4. Finish the workout in-app → verify Live Activity disappears

### Set Completion Test
1. Start a workout, lock the phone
2. On lock screen: tap the Complete button
3. Verify rest timer countdown appears
4. Wait for timer to expire → verify sound plays and next set appears

### +/- Button Test
1. Start a workout, lock the phone
2. Tap weight "+" button → verify weight increments by 1
3. Tap reps "−" button → verify reps decrements by 1
4. Unlock phone, open app → verify in-app values match lock screen changes

### Crash Recovery Test
1. Start a workout with Live Activity showing
2. Force-quit the app from app switcher
3. Verify Live Activity remains on lock screen
4. Reopen the app → verify workout resumes and Live Activity reconnects

## Key Development Notes

- **ContentState updates**: Only call `Activity.update()` when data actually changes. Never update per-second for the timer — `Text(timerInterval:)` handles that automatically.
- **Intent split pattern**: Intent struct declarations go in `Kiln/Shared/` (both targets). `perform()` implementations go in target-specific files. This prevents compilation errors from the widget extension trying to access SwiftData.
- **Asset duplication**: Colors and icons used in the Live Activity must be duplicated in `KilnWidgets/Assets.xcassets`. The widget extension cannot access the main app's asset catalog at runtime.
- **Simulator limitations**: Live Activities render in the Simulator but interactive buttons (App Intents) may not work correctly. Always test on a physical device.
