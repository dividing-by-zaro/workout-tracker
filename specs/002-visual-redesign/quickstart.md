# Quickstart: Visual Redesign — Fire Theme

**Branch**: `002-visual-redesign` | **Date**: 2026-02-22

## Prerequisites

- Xcode 15+ with iOS 17 SDK
- `xcodegen` installed (`brew install xcodegen`)
- The repo checked out on branch `002-visual-redesign`

## Build & Run

```bash
cd /Users/isabelgwara/Documents/github/workout-tracker
xcodegen generate
open Kiln.xcodeproj
# Cmd+R to build and run on simulator or device
```

## Implementation Order

1. **DesignSystem.swift** — Update all color tokens, add Shadow/Grain/CornerRadius sections
2. **Noise asset** — Create and add `noise_tile.png` (200x200 seamless) to `Assets.xcassets`
3. **GrainOverlay view modifier** — Create `GrainedBackground` modifier in Design/
4. **project.yml + KilnApp.swift** — Force light mode (Info.plist + `.preferredColorScheme`)
5. **ContentView.swift** — Tab bar appearance (dark warm background, fire accent)
6. **View files (16 files)** — Apply grain backgrounds, warm shadows, fix hardcoded colors
7. **Verify** — Walk through all screens, check contrast, check Reduce Transparency toggle

## Key Files

| File | Role |
|------|------|
| `Kiln/Design/DesignSystem.swift` | Central design token definitions |
| `Kiln/KilnApp.swift` | App entry, force light mode |
| `project.yml` | Build config, Info.plist UIUserInterfaceStyle |
| `Kiln/Views/ContentView.swift` | Tab bar configuration |
| `Kiln/Views/Workout/*.swift` | 7 workout-related views |
| `Kiln/Views/Templates/*.swift` | 2 template editing views |
| `Kiln/Views/History/*.swift` | 3 history views |
| `Kiln/Views/Profile/*.swift` | 2 profile views |

## Verification Checklist

- [ ] All 3 tabs render with warm cream background
- [ ] Template cards have warm shadows and grain
- [ ] Tab bar is dark warm brown with fire accent on active tab
- [ ] Rest timer uses ember tones
- [ ] Chart bars use fire accent color
- [ ] No dark theme remnants visible on any screen
- [ ] Text meets WCAG AA contrast on all backgrounds
- [ ] Grain hides when Reduce Transparency is enabled
- [ ] No hardcoded Color literals outside DesignSystem.swift
