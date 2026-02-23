# Feature Specification: Visual Redesign — Fire Theme

**Feature Branch**: `002-visual-redesign`
**Created**: 2026-02-22
**Status**: Draft
**Input**: User description: "Let's work on a visual redesign of the app. I want it to be a light theme with a burning / embers / fire undertone - with oranges, reds, blacks and browns as accents, with a grainy texture and shadows throughout. we should maintain a clean & modern design, but it should have some life to it, and character"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Light Fire Theme Across All Screens (Priority: P1)

A user opens the app and sees a warm, light-themed interface with a creamy off-white background accented by fire-inspired tones — deep oranges, ember reds, charcoal blacks, and warm browns. The design feels clean and modern but has a distinctive, characterful edge: subtle grain texture overlays and soft shadows give every surface a tactile, lived-in quality. All existing screens (Workouts, History, Profile) reflect this new visual identity consistently.

**Why this priority**: The core visual identity must be established first — every other story depends on the palette, textures, and shadow language being defined and applied globally.

**Independent Test**: Open the app, navigate through all three tabs, and verify the light theme with fire-tone accents renders consistently. Compare against the current dark theme to confirm the transformation is complete.

**Acceptance Scenarios**:

1. **Given** the app launches, **When** the user views the Workouts tab, **Then** backgrounds are light/warm cream, text is dark, accent colors are fire-toned (orange, red, brown), and a subtle grain texture is visible on surfaces.
2. **Given** the user navigates between tabs, **When** switching from Workouts to History to Profile, **Then** the visual language (palette, texture, shadows) is consistent across all screens.
3. **Given** any elevated surface (cards, sheets, modals), **When** displayed, **Then** it has a soft shadow and visible grain texture that distinguishes it from the background.

---

### User Story 2 — Template & Workout Cards Feel Warm and Tactile (Priority: P1)

When viewing workout template cards on the Start Workout screen, each card has warm-toned backgrounds with subtle shadows that make them feel lifted off the page. The "Start" button uses the primary ember/orange accent. Body-part icons tint to match the fire palette. The card surfaces carry the grain texture, giving a paper-like quality.

**Why this priority**: Template cards are the first thing users interact with — they set the visual tone for the entire experience.

**Independent Test**: View the Start Workout screen with at least two templates. Verify cards have visible shadow depth, grain texture, warm accent colors on icons and buttons, and clear visual hierarchy against the light background.

**Acceptance Scenarios**:

1. **Given** the Workouts tab with templates, **When** the user views template cards, **Then** each card has a warm surface color, soft drop shadow, and visible grain texture.
2. **Given** a template card, **When** the user looks at the "Start" button, **Then** it uses the primary fire accent color (ember orange-red) and contrasts clearly against the card.
3. **Given** body-part icons on a template card, **When** displayed, **Then** icons tint using the fire palette accent colors (not the previous red-only tint).

---

### User Story 3 — Tab Bar and Navigation Feel Grounded (Priority: P2)

The tab bar at the bottom uses warm, dark tones (charcoal or deep brown) to anchor the interface visually. The selected tab icon uses the primary fire accent, while unselected icons are a muted warm gray. The navigation title area at the top has a subtle warmth rather than a stark white.

**Why this priority**: Navigation chrome frames every screen and must reinforce the theme without competing with content.

**Independent Test**: View the tab bar and navigation bar across all three tabs. Verify the tab bar uses a dark warm tone, selected state uses the fire accent, and the top navigation area has warmth.

**Acceptance Scenarios**:

1. **Given** any screen, **When** the user looks at the tab bar, **Then** it uses a warm dark background (charcoal/deep brown), the active tab icon is the fire accent color, and inactive icons are muted warm gray.
2. **Given** any screen, **When** the user views the navigation title, **Then** the title text is dark and the background has a subtle warm tint rather than pure white.

---

### User Story 4 — Active Workout Session Carries the Theme (Priority: P2)

During an active workout, the exercise cards, set rows, input fields, and rest timer all use the fire theme. Completed sets use a warm success color. The rest timer ring and background use ember tones. Input fields have warm borders and grain-textured backgrounds.

**Why this priority**: The active workout is where users spend the most time — it must feel cohesive with the rest of the redesign.

**Independent Test**: Start a workout, log sets, trigger the rest timer. Verify all elements use the fire palette, grain textures, and shadow language.

**Acceptance Scenarios**:

1. **Given** an active workout, **When** viewing exercise cards, **Then** they use warm surface colors, fire-palette accents, shadows, and grain texture.
2. **Given** a completed set, **When** marked done, **Then** the visual indicator uses a warm success color (amber/gold rather than bright green).
3. **Given** the rest timer, **When** active, **Then** the timer ring and background use ember/fire tones consistent with the overall theme.

---

### User Story 5 — History and Profile Screens Reflect the Theme (Priority: P2)

The History list view, workout detail cards, and Profile screen (including the workouts-per-week chart) all use the fire theme. Chart bars use fire accent colors. History cards have the same warm, textured treatment as template cards.

**Why this priority**: Ensures visual completeness across the entire app, not just the primary workout flow.

**Independent Test**: Navigate to History and Profile tabs. Verify cards, charts, and all UI elements use the fire palette, textures, and shadows consistently.

**Acceptance Scenarios**:

1. **Given** the History tab, **When** viewing workout history cards, **Then** they use warm surfaces, fire-toned accents, shadows, and grain texture.
2. **Given** the Profile tab, **When** viewing the workouts-per-week chart, **Then** chart bars use fire accent colors (orange/ember) and the chart background is warm-toned.
3. **Given** any detail view (workout detail, template editor), **When** opened, **Then** it carries the same visual treatment as the parent screen.

---

### User Story 6 — Grain Texture Overlay (Priority: P3)

A subtle noise/grain texture is visible on primary surfaces (main background and card surfaces). The grain is fine enough to add character without reducing readability. It should evoke a paper-like or ash-like quality.

**Why this priority**: The grain is a polish detail — the app should look good with flat warm colors first, then the grain adds the final layer of character.

**Independent Test**: Take a screenshot and zoom in on a card surface and the background. Verify fine grain noise is visible but does not interfere with text legibility.

**Acceptance Scenarios**:

1. **Given** any screen, **When** the user views the background, **Then** a subtle grain/noise texture is visible at normal viewing distance.
2. **Given** any text over a grain-textured surface, **When** reading, **Then** the grain does not reduce text legibility or contrast.
3. **Given** the grain texture, **When** viewed on different screen sizes, **Then** the grain density remains consistent and doesn't become blocky or overwhelming.

---

### Edge Cases

- What happens when the user has system dark mode enabled? The app should always display the fire light theme regardless of system appearance setting.
- What happens on OLED screens where pure white can be harsh? The warm cream background avoids pure white, mitigating OLED glare.
- What happens with accessibility (Dynamic Type, Reduce Transparency, Increase Contrast)? Text contrast ratios must meet WCAG AA standards (4.5:1 for body text, 3:1 for large text) against all warm background colors. Grain texture should respect "Reduce Transparency" by becoming less prominent or hidden.
- What happens with the exercise picker and other modal sheets? They use the same fire theme (warm backgrounds, fire accents, grain texture, shadows).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST use a light-themed color palette with warm cream/off-white backgrounds, replacing the current dark theme.
- **FR-002**: Accent colors MUST be drawn from a fire/ember palette: deep orange, ember red, charcoal black, and warm brown.
- **FR-003**: All elevated surfaces (cards, sheets, modals, alerts) MUST display soft drop shadows to create depth.
- **FR-004**: A subtle grain/noise texture MUST be applied to primary background surfaces and card surfaces.
- **FR-005**: The grain texture MUST NOT reduce text legibility — all text MUST meet WCAG AA contrast ratios (4.5:1 body, 3:1 large text) against their backgrounds.
- **FR-006**: The tab bar MUST use a warm dark tone (charcoal or deep brown) with fire-accent selected states.
- **FR-007**: All body-part icons MUST tint using the fire palette accent colors.
- **FR-008**: The "Start" button and primary action buttons MUST use the primary fire accent color (ember orange-red).
- **FR-009**: The rest timer MUST use ember/fire tones for its ring and background.
- **FR-010**: The workouts-per-week chart MUST use fire accent colors for bar fills.
- **FR-011**: The DesignSystem color tokens MUST be updated to reflect the new palette (no hardcoded colors outside the design system).
- **FR-012**: The app MUST display the fire light theme regardless of the user's system appearance (light/dark) setting.
- **FR-013**: The grain texture MUST respect the "Reduce Transparency" accessibility setting by becoming hidden or significantly reduced.

### Key Entities

- **Color Palette**: The set of named color tokens — primary, secondary, background, surface, text primary, text secondary, success, accent variants — defined in the design system.
- **Grain Texture**: A noise/grain overlay asset or procedural effect applied to surfaces to add visual character.
- **Shadow Style**: A defined shadow configuration (offset, blur, color, opacity) applied consistently to elevated surfaces.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of screens (Workouts, History, Profile, Active Workout, Template Editor, Exercise Picker, Workout Detail) render with the fire light theme — no remnants of the dark theme remain.
- **SC-002**: All text elements meet WCAG AA contrast ratios (4.5:1 for body text, 3:1 for large text) against their respective backgrounds.
- **SC-003**: The grain texture is visible at 1x zoom on a standard display but does not reduce text readability (verified by visual inspection).
- **SC-004**: All color values are sourced from the centralized design system — zero hardcoded color literals appear outside the design system file.
- **SC-005**: The visual redesign introduces no new user-facing functionality — all existing features continue to work identically.

## Assumptions

- The redesign is cosmetic only — no changes to navigation structure, data models, or functionality.
- "Light theme" means light backgrounds with dark text (inverting the current dark-on-dark scheme).
- The grain texture will be a static image asset overlaid with low opacity, not a runtime-generated procedural effect, for performance.
- The fire palette primary accent will be an ember orange-red (warmer than the current pure red), with secondary accents in burnt orange, warm brown, and charcoal.
- The app will force light appearance at the app level, overriding system dark mode.
- Shadow styles will use warm-tinted shadows (slightly brown/orange cast) rather than neutral gray shadows, to reinforce the fire theme.
