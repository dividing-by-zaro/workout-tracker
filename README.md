Kiln is a personal workout tracker iOS app — custom software built as an upgrade to Strong.

## Status

MVP implementation complete. Live Activity feature on branch `003-live-activity`.

## Features (MVP)

- [x] Project constitution and design principles
- [x] Feature spec with 7 user stories and 21 functional requirements
- [x] Implementation plan with architecture decisions
- [x] Data model (6 entities)
- [x] One-tap workout start from templates
- [x] Set logging with pre-filled previous data, tap-anywhere completion, flame/brick status icons
- [x] Inline rest timer (appears below completed set, auto-hides, 120s default)
- [x] Mid-workout modifications (add/swap/remove exercises and sets)
- [x] Crash-safe workout recovery (zero data loss)
- [x] Workout template creation and management
- [x] Workout history with detail view
- [x] Profile with workout count and workouts-per-week chart
- [x] Strong CSV import (1,734 rows of historical data)
- [x] Equipment type system (barbell, dumbbell, kettlebell, machine, bodyweight, etc.)
- [x] Custom body-part icons on template cards
- [x] Template detail modal with full exercise list
- [x] Exercise picker with equipment type and body part selection
- [x] Edit and delete completed workouts from history (long-press context menu)
- [x] Tap completed set to uncomplete (toggle), swipe-left to delete sets
- [x] Delete All Data utility in Profile (with confirmation)
- [x] Set completion/uncomplete bounce animations, rest timer appear/dismiss transitions
- [x] Custom app icon
- [x] Fire light theme (warm cream, fire red accents, grain texture, warm shadows)
- [x] Custom numeric keyboard with +/− buttons and auto-replace on focus
- [x] Live Activity on lock screen — complete entire workout without unlocking
  - [x] Current exercise, set progress, previous set info
  - [x] Adjustable weight/reps with +/− buttons
  - [x] Complete Set button with auto-advancing rest timer
  - [x] Countdown timer with progress bar and Skip button
  - [x] Sound alert on timer expiry, auto-advance to next set

## Getting Started

1. Run `xcodegen generate` (requires [xcodegen](https://github.com/yonaskolb/XcodeGen))
2. Open `Kiln.xcodeproj` in Xcode
3. Select iPhone 13 simulator (iOS 17+)
4. Build and run (Cmd+R)
5. Import `strong_workouts.csv` from the Profile tab

## Future

- Server sync via Railway backend
- Exercise progression graphs
- Muscle group tracking
- Export to CSV/JSON

## Tech Stack

Swift 5.9+ / SwiftUI / SwiftData / Swift Charts / ActivityKit / WidgetKit / AppIntents / iOS 17+
