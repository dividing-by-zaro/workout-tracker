# Quickstart: Celebration Screen

## Prerequisites

- Xcode (Swift 5.9+, iOS 17+ SDK)
- `xcodegen` installed (`brew install xcodegen`)

## Build & Run

```bash
# Regenerate project after adding new Swift files
xcodegen generate

# Open in Xcode
open Kiln.xcodeproj
# Build: Cmd+R (target: iPhone 13 simulator or device)
```

## Files to Create

| File | Purpose |
|------|---------|
| `Kiln/Models/CelebrationData.swift` | Value type struct with workout summary stats |
| `Kiln/Views/Workout/CelebrationView.swift` | Full-screen celebration SwiftUI view |

## Files to Modify

| File | Change |
|------|--------|
| `Kiln/Services/WorkoutSessionManager.swift` | Add `celebrationData` property, compute stats in `finishWorkout()` before clearing state |
| `Kiln/Views/ContentView.swift` | Add `.fullScreenCover` presentation tied to `celebrationData` |
| `project.yml` | Add new Swift files to Kiln target sources (xcodegen handles this via directory glob) |

## Key Patterns to Follow

- **DesignSystem**: Use `DesignSystem.Colors.*`, `DesignSystem.Typography.*`, `DesignSystem.Spacing.*` for all visual tokens
- **Grain texture**: Apply `.grainedBackground()` for full-screen backgrounds, `CardGrainOverlay()` for card surfaces
- **Shadows**: Use `.cardShadow()` for stat cards, `.elevatedShadow()` for prominent elements
- **Animations**: Spring animations with `response: 0.35, dampingFraction: 0.75` for state transitions; `.scale.combined(with: .opacity)` for insertions
- **@Observable**: WorkoutSessionManager is `@Observable`, so `celebrationData` changes automatically trigger view updates

## Verification

1. Start a workout from a template
2. Complete at least one set
3. Tap "End" → "Finish"
4. Celebration screen should appear with correct stats
5. Tap dismiss → returns to template grid
6. Repeat with "Finish & Update Template" — same behavior
7. Test with different exercise types (strength, bodyweight, cardio)
