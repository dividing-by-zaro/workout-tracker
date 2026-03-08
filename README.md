Kiln is a personal workout tracker iOS app — custom software built as an upgrade to Strong.

## Status

MVP implementation complete. Timer backend for APNS Live Activity push on branch `006-hybrid-timer-backend`.

## Features (MVP)

- [x] Project constitution and design principles
- [x] Feature spec with 7 user stories and 21 functional requirements
- [x] Implementation plan with architecture decisions
- [x] Data model (6 entities)
- [x] One-tap workout start from templates
- [x] Set logging with pre-filled previous data, tap-anywhere completion, flame/brick status icons
- [x] Inline rest timer (appears below completed set, auto-hides, 120s default)
- [x] Mid-workout modifications (add/swap/remove/reorder exercises and sets)
- [x] "Finish & Update Template" — propagate exercise changes back to the source template
- [x] Crash-safe workout recovery (auto-resume with toast, zero data loss)
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
  - [x] Countdown timer with progress bar, Skip button, and next set preview
  - [x] Sound alert on timer expiry, auto-advance to next set
  - [x] No FaceID required — UserDefaults cache eliminates SwiftData access from lock screen
  - [x] Local notification alert on timer expiry (works even when app is killed)
  - [x] Backend-driven APNS push updates Live Activity when app is backgrounded/locked
  - [x] ~~Background audio~~ removed — local notifications + APNS push handle all background timer alerts
- [x] Celebration screen on workout completion
  - [x] Ordinal workout count ("Your 47th workout!")
  - [x] Adaptive stats: duration, weight lifted, sets, reps, distance (only relevant metrics shown)
  - [x] Ember particle animation and staggered stat entrance

## Getting Started

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` and fill in backend URL + API key
2. Run `xcodegen generate` (requires [xcodegen](https://github.com/yonaskolb/XcodeGen))
3. Open `Kiln.xcodeproj` in Xcode
4. Select iPhone 13 simulator (iOS 17+)
5. Build and run (Cmd+R)
6. Import `strong_workouts.csv` from the Profile tab

## Future

- Server sync
- Exercise progression graphs
- Muscle group tracking
- Export to CSV/JSON

## Tech Stack

- **iOS**: Swift 5.9+ / SwiftUI / SwiftData / Swift Charts / ActivityKit / WidgetKit / AppIntents / iOS 17+
- **Backend**: Python 3.12 / FastAPI / httpx / PyJWT (timer microservice on Coolify)
