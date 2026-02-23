# Research: Visual Redesign — Fire Theme

**Branch**: `002-visual-redesign` | **Date**: 2026-02-22

## R1: Grain Texture Approach

**Decision**: Static PNG tile overlay with `.resizable(resizingMode: .tile)` + `.blendMode(.overlay)` at 0.04–0.06 opacity.

**Rationale**: Most performant and simplest approach. The image loads once into GPU texture memory and tiles with zero per-frame cost. A 200x200 seamless noise PNG is ~256 KB in GPU memory. This is the industry-standard pattern used by Flighty, Arc, and other premium iOS apps with textured backgrounds.

**Alternatives considered**:

| Approach | Performance | Complexity | Verdict |
|----------|------------|------------|---------|
| PNG tile overlay | Excellent | Low | **Chosen** — simplest, most predictable |
| Metal shader (`.colorEffect`) | Excellent | Medium | Good alternative but adds `.metal` file complexity with no visual benefit for static grain |
| CIRandomGenerator | Good (if cached) | Medium | Unnecessary overhead — must generate and cache; no advantage over static tile |
| SwiftUI Canvas | Poor | High | Drawing thousands of rects in Swift — too slow |

**Accessibility**: Use `@Environment(\.accessibilityReduceTransparency)` to conditionally hide the grain overlay when the user has "Reduce Transparency" enabled. Do NOT use `UIAccessibility.isReduceTransparencyEnabled` — it doesn't trigger SwiftUI view updates.

## R2: Warm-Tinted Shadows

**Decision**: Custom shadow colors defined in DesignSystem, using brown-tinted `Color` at 10–15% opacity rather than SwiftUI's default neutral gray shadow.

**Rationale**: Default `.shadow()` uses neutral gray which feels cold against warm backgrounds. A shadow tinted toward `rgb(0.35, 0.22, 0.14)` at ~12% opacity looks natural on cream. Use layered shadows (tight + diffuse) for premium depth.

**Key implementation detail**: Apply `.compositingGroup()` before `.shadow()` on complex view hierarchies (VStack, HStack with multiple children) to prevent individual child shadows from overlapping.

**Shadow definitions**:
- **Card shadow**: `Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.12)`, radius 8, y-offset 4
- **Elevated shadow** (sheets/modals): Same hue at 0.18 opacity, radius 16, y-offset 8

## R3: Forcing Light Mode

**Decision**: Use both `Info.plist` `UIUserInterfaceStyle = Light` AND `.preferredColorScheme(.light)` on the root WindowGroup.

**Rationale**: Info.plist is the most reliable — it catches system alerts, UIKit-backed components, date pickers, and status bar. The SwiftUI modifier provides an explicit code-level safety net. Using both covers all edge cases.

**Implementation**:
1. Add `UIUserInterfaceStyle: Light` to `project.yml` under `Info.plist` settings (since project uses xcodegen)
2. Add `.preferredColorScheme(.light)` to ContentView in KilnApp.swift

## R4: Color Palette Design

**Decision**: Warm cream backgrounds, ember orange-red primary, charcoal and brown accents.

**Rationale**: The user wants a "light theme with burning/embers/fire undertone." The current dark theme uses near-black (#121213) background with red (#EB4238) accent. The new palette inverts to light backgrounds while shifting the red accent warmer (toward orange-red) and adding brown/charcoal secondary tones.

**Proposed palette** (exact hex values to be finalized during implementation):

| Token | Current (Dark) | New (Fire Light) | Notes |
|-------|----------------|-------------------|-------|
| `primary` | `#EB4238` (red) | `#D4592A` (ember orange-red) | Warmer, more fire-like |
| `secondary` | N/A | `#8B4513` (warm brown) | New token for secondary accents |
| `background` | `#121213` (near-black) | `#F5F0EB` (warm cream) | Light, warm, not pure white |
| `surface` | `#242428` (dark gray) | `#FFFFFF` (white) | Cards on cream background |
| `textPrimary` | `#FFFFFF` (white) | `#1A1A1A` (near-black) | Inverted for light theme |
| `textSecondary` | `#999999` (gray 60%) | `#6B5B4F` (warm gray-brown) | Warm rather than neutral gray |
| `success` | `#4DC765` (green) | `#C4873A` (amber/gold) | Warm success tone matching fire palette |
| `timerActive` | `#EB4238` (red) | `#D4592A` (ember orange-red) | Same as primary |
| `timerBackground` | `#331919` (dark red) | `#FDE8D8` (warm peach tint) | Light warm background for timer |
| `tabBar` | N/A | `#2C1810` (dark warm brown) | New token for tab bar |
| `tabInactive` | N/A | `#9E8E82` (muted warm gray) | New token for inactive tab icons |
| `destructive` | N/A | `#C0392B` (dark red) | Explicit destructive action color |

## R5: Current Codebase Audit

**Files requiring changes** (16 Swift files + 1 config file + 1 image asset):

| File | Change Scope |
|------|-------------|
| `Kiln/Design/DesignSystem.swift` | Complete palette rewrite + add Shadow/Grain sections |
| `Kiln/KilnApp.swift` | Add `.preferredColorScheme(.light)` |
| `project.yml` | Add `UIUserInterfaceStyle: Light` to Info.plist |
| `Kiln/Views/ContentView.swift` | Tab bar appearance configuration |
| `Kiln/Views/Workout/StartWorkoutView.swift` | Background + grain |
| `Kiln/Views/Workout/ActiveWorkoutView.swift` | Background, shadows, fix hardcoded `.white` and `.red` |
| `Kiln/Views/Workout/TemplateCardView.swift` | Card shadows, grain, fix hardcoded `.white` |
| `Kiln/Views/Workout/ExerciseCardView.swift` | Card shadows, surface colors |
| `Kiln/Views/Workout/SetRowView.swift` | Input field styling, success color |
| `Kiln/Views/Workout/RestTimerView.swift` | Timer colors |
| `Kiln/Views/Workout/ExercisePickerView.swift` | List/form appearance |
| `Kiln/Views/Templates/TemplateEditorView.swift` | Form appearance, fix `.secondary` |
| `Kiln/Views/Templates/TemplateExerciseRow.swift` | Minimal — secondary color |
| `Kiln/Views/History/HistoryListView.swift` | Background + grain |
| `Kiln/Views/History/WorkoutCardView.swift` | Card shadows, surface colors |
| `Kiln/Views/History/WorkoutDetailView.swift` | Background, card shadows |
| `Kiln/Views/Profile/ProfileView.swift` | Background, card shadows, icon color |
| `Kiln/Views/Profile/WorkoutsPerWeekChart.swift` | Bar chart accent color |

**Hardcoded colors to fix** (5 instances):
1. `ActiveWorkoutView.swift:117` — `.foregroundStyle(.white)` → `DesignSystem.Colors.textOnPrimary`
2. `ActiveWorkoutView.swift:178` — `.tint(.red)` → `DesignSystem.Colors.destructive`
3. `TemplateCardView.swift:30` — `.foregroundStyle(.white)` → `DesignSystem.Colors.textOnPrimary`
4. `TemplateCardView.swift:177` — `.foregroundStyle(.white)` → `DesignSystem.Colors.textOnPrimary`
5. `TemplateEditorView.swift:28` — `.foregroundStyle(.secondary)` → `DesignSystem.Colors.textSecondary`

## R6: Asset Requirements

**New assets needed**:
- `noise_tile` — 200x200 seamless noise PNG (grayscale, alpha channel) added to `Assets.xcassets`

**Existing assets impacted**:
- Body-part icons (8 imagesets) — currently tinted with `DesignSystem.Colors.primary`. Will automatically pick up the new primary color since they use rendering mode "template."
