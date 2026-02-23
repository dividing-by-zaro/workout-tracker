Kiln is a personal workout tracker iOS app — custom software built as an upgrade to Strong.

## Status

MVP implementation complete. Ready for Xcode build and testing.

## Features (MVP)

- [x] Project constitution and design principles
- [x] Feature spec with 7 user stories and 21 functional requirements
- [x] Implementation plan with architecture decisions
- [x] Data model (6 entities)
- [x] One-tap workout start from templates
- [x] Set logging with pre-filled previous data, tap-anywhere completion, flame/brick status icons
- [x] Inline rest timer (appears below completed set, auto-hides, 120s default) with background notifications
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

## Getting Started

1. Run `xcodegen generate` (requires [xcodegen](https://github.com/yonaskolb/XcodeGen))
2. Open `Kiln.xcodeproj` in Xcode
3. Select iPhone 17 simulator (iOS 17+)
4. Build and run (Cmd+R)
5. Import `strong_workouts.csv` from the Profile tab

## Future

- Live Activity on lock screen (set completion + rest timer countdown)
- Server sync via Railway backend
- Exercise progression graphs
- Muscle group tracking
- Export to CSV/JSON

## Tech Stack

Swift 5.9+ / SwiftUI / SwiftData / Swift Charts / iOS 17+ / iPhone 17
