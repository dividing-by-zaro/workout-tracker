# Tasks: Visual Redesign — Fire Theme

**Input**: Design documents from `specs/002-visual-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks grouped by user story. US1 and US2 are both P1 (MVP). US3–US5 are P2. US6 is P3 (polish).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US6) this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create new assets and configure app-wide light mode

- [x] T001 Create seamless 200x200 noise tile PNG and add as `noise_tile` imageset in `Kiln/Assets.xcassets/noise_tile.imageset/` (1x, 2x, 3x variants)
- [x] T002 Add `UIUserInterfaceStyle: Light` to Info.plist properties in `project.yml`
- [x] T003 Add `.preferredColorScheme(.light)` to the WindowGroup in `Kiln/KilnApp.swift`

---

## Phase 2: Foundational (Design System Rewrite)

**Purpose**: Rewrite the centralized design tokens — BLOCKS all view changes

**CRITICAL**: No view file work can begin until this phase is complete

- [x] T004 Rewrite color palette in `Kiln/Design/DesignSystem.swift` — replace all 8 existing color tokens with the 14-token fire light palette (primary → ember orange-red `#D4592A`, background → warm cream `#F5F0EB`, surface → white, textPrimary → near-black `#1A1A1A`, textSecondary → warm gray-brown `#6B5B4F`, textOnPrimary → white, success → amber `#C4873A`, destructive → dark red `#C0392B`, timerActive → `#D4592A`, timerBackground → warm peach `#FDE8D8`, secondary → warm brown `#8B4513`, surfaceSecondary → `#EDE5DD`, tabBar → `#2C1810`, tabInactive → `#9E8E82`)
- [x] T005 Add `Shadows` enum to `Kiln/Design/DesignSystem.swift` with `cardShadow` (color: `Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.12)`, radius: 8, y: 4) and `elevatedShadow` (same hue, opacity 0.18, radius: 16, y: 8)
- [x] T006 Add `CornerRadius` enum to `Kiln/Design/DesignSystem.swift` with `card: 12`, `button: 10`, and `chip: CGFloat = 100` (capsule equivalent)
- [x] T007 Create `GrainedBackground` ViewModifier in `Kiln/Design/DesignSystem.swift` (or a new file `Kiln/Design/GrainOverlay.swift`) that applies the noise tile as a tiled overlay at 0.05 opacity with `.blendMode(.overlay)`, respecting `@Environment(\.accessibilityReduceTransparency)` to hide the grain when enabled. Add a `.grainedBackground(_:)` View extension.

**Checkpoint**: DesignSystem tokens complete — all view file work can now proceed

---

## Phase 3: User Story 1 — Light Fire Theme Across All Screens (Priority: P1) MVP

**Goal**: Replace dark backgrounds with warm cream across all three tabs. Grain texture visible on backgrounds. Consistent fire palette on every screen.

**Independent Test**: Open the app, navigate through Workouts → History → Profile tabs. Verify warm cream backgrounds, dark text, fire-toned accents, and grain texture visible on all screens.

### Implementation for User Story 1

- [x] T008 [US1] Update `Kiln/Views/Workout/StartWorkoutView.swift` — replace `.background(DesignSystem.Colors.background)` with `.grainedBackground()`, ensure title and add-button use updated tokens
- [x] T009 [US1] Update `Kiln/Views/History/HistoryListView.swift` — replace `.background(DesignSystem.Colors.background)` with `.grainedBackground()`, verify empty-state text uses updated `textSecondary`
- [x] T010 [US1] Update `Kiln/Views/History/WorkoutDetailView.swift` — replace `.background(DesignSystem.Colors.background)` with `.grainedBackground()`
- [x] T011 [US1] Update `Kiln/Views/Profile/ProfileView.swift` — replace `.background(DesignSystem.Colors.background)` with `.grainedBackground()`
- [x] T012 [US1] Update `Kiln/Views/Workout/ActiveWorkoutView.swift` — replace `.background(DesignSystem.Colors.background)` with `.grainedBackground()`

**Checkpoint**: All 3 tabs + active workout show warm cream backgrounds with grain. Fire palette renders through updated tokens.

---

## Phase 4: User Story 2 — Template & Workout Cards Feel Warm and Tactile (Priority: P1)

**Goal**: Template cards have warm surface backgrounds, soft warm shadows, and grain texture. "Start" button uses fire accent. Body-part icons tint with fire palette.

**Independent Test**: View Start Workout screen with 2+ templates. Cards have visible shadow depth, grain texture, fire accents on icons and buttons.

### Implementation for User Story 2

- [x] T013 [US2] Update `Kiln/Views/Workout/TemplateCardView.swift` — add `.compositingGroup()` and warm card shadow using `DesignSystem.Shadows.cardShadow`, replace `.background(DesignSystem.Colors.surface)` with surface + grain overlay, fix hardcoded `.foregroundStyle(.white)` on Start button text (lines 30, 177) to use `DesignSystem.Colors.textOnPrimary`, update metadata pill backgrounds to `surfaceSecondary`
- [x] T014 [P] [US2] Update `Kiln/Views/History/WorkoutCardView.swift` — add `.compositingGroup()` and warm card shadow using `DesignSystem.Shadows.cardShadow`
- [x] T015 [P] [US2] Update `Kiln/Views/Workout/ExerciseCardView.swift` — add `.compositingGroup()` and warm card shadow using `DesignSystem.Shadows.cardShadow`

**Checkpoint**: All card surfaces have warm shadows and tactile feel. No hardcoded `.white` on buttons.

---

## Phase 5: User Story 3 — Tab Bar and Navigation Feel Grounded (Priority: P2)

**Goal**: Tab bar uses warm dark background with fire accent on active tab. Navigation title areas have warm tint.

**Independent Test**: View tab bar across all 3 tabs. Dark warm background, fire accent on selected tab, muted warm gray on inactive tabs.

### Implementation for User Story 3

- [x] T016 [US3] Update `Kiln/Views/ContentView.swift` — configure `UITabBar.appearance()` in an `.onAppear` or `init()` block to set `backgroundColor` to `DesignSystem.Colors.tabBar`, `unselectedItemTintColor` to `DesignSystem.Colors.tabInactive` (as UIColor), and keep `.tint(DesignSystem.Colors.primary)` for selected state
- [x] T017 [US3] Update `Kiln/Views/Workout/StartWorkoutView.swift` — ensure the "Workouts" title and navigation area use warm-toned styling (dark text on warm background, no stark white navigation bar)
- [x] T018 [P] [US3] Update `Kiln/Views/History/HistoryListView.swift` — ensure navigation title renders with dark text on warm background
- [x] T019 [P] [US3] Update `Kiln/Views/Profile/ProfileView.swift` — ensure navigation/header area renders with dark text on warm background

**Checkpoint**: Tab bar is dark warm brown, active tab is fire accent, inactive tabs are muted warm gray. Navigation titles are dark on warm.

---

## Phase 6: User Story 4 — Active Workout Session Carries the Theme (Priority: P2)

**Goal**: Exercise cards, set rows, input fields, rest timer, and completion indicators all use fire theme. Success color is amber/gold. Rest timer uses ember tones.

**Independent Test**: Start a workout, log sets, trigger rest timer. All elements use fire palette, warm surfaces, shadows.

### Implementation for User Story 4

- [x] T020 [US4] Update `Kiln/Views/Workout/ActiveWorkoutView.swift` — fix hardcoded `.foregroundStyle(.white)` on Finish button (line 117) to `DesignSystem.Colors.textOnPrimary`, fix `.tint(.red)` on Discard button (line 178) to `DesignSystem.Colors.destructive`, update header/footer surface backgrounds, add card shadows to header section
- [x] T021 [US4] Update `Kiln/Views/Workout/SetRowView.swift` — verify completed-set checkmark uses updated `success` token (amber/gold), verify input field styling works on light background (`.roundedBorder` TextField style may need custom styling for warm look)
- [x] T022 [US4] Update `Kiln/Views/Workout/RestTimerView.swift` — timer stroke colors now use updated `timerActive` (ember) and `timerBackground` (warm peach) tokens; verify the container background renders warm peach, skip button uses updated primary
- [x] T023 [P] [US4] Update `Kiln/Views/Workout/ExercisePickerView.swift` — ensure List/Form appearance uses warm backgrounds; fix system-default list styling for light theme compatibility

**Checkpoint**: Active workout is fully themed. Timer is ember-toned. Completed sets show amber/gold. No hardcoded colors remain.

---

## Phase 7: User Story 5 — History and Profile Screens Reflect the Theme (Priority: P2)

**Goal**: History cards, workout detail, and profile screen (including chart) all use fire theme with warm shadows.

**Independent Test**: Navigate History and Profile tabs. Cards, charts, and all UI elements use fire palette, textures, shadows.

### Implementation for User Story 5

- [x] T024 [US5] Update `Kiln/Views/History/WorkoutDetailView.swift` — add warm card shadows to exercise section backgrounds using `DesignSystem.Shadows.cardShadow` with `.compositingGroup()`
- [x] T025 [US5] Update `Kiln/Views/Profile/WorkoutsPerWeekChart.swift` — bar chart `.foregroundStyle` already references `DesignSystem.Colors.primary` which will pick up the new ember color; verify chart background and axis labels render well on warm cream
- [x] T026 [US5] Update `Kiln/Views/Profile/ProfileView.swift` — add warm card shadow to chart container and import button sections, update profile icon color (already uses `primary`)

**Checkpoint**: History and Profile fully themed. Chart bars are ember-orange. All detail views carry fire treatment.

---

## Phase 8: User Story 6 — Grain Texture Overlay (Priority: P3)

**Goal**: Fine grain texture visible on background and card surfaces. Does not reduce readability. Respects Reduce Transparency.

**Independent Test**: Screenshot and zoom to verify grain is visible but doesn't interfere with text. Toggle Reduce Transparency in Settings > Accessibility to verify grain hides.

### Implementation for User Story 6

- [x] T027 [US6] Add grain overlay to card surfaces in `Kiln/Views/Workout/TemplateCardView.swift` — layer a scaled-down grain over the card surface (lower opacity than background grain, e.g., 0.03) for paper-like quality
- [x] T028 [P] [US6] Add grain overlay to card surfaces in `Kiln/Views/History/WorkoutCardView.swift` — same treatment as template cards
- [x] T029 [P] [US6] Add grain overlay to card surfaces in `Kiln/Views/Workout/ExerciseCardView.swift` — same treatment as template cards
- [x] T030 [US6] Verify grain density on multiple screen sizes (iPhone SE, iPhone 15, iPhone 15 Pro Max) in Xcode previews or simulator — grain should be consistent, not blocky
- [x] T031 [US6] Test Reduce Transparency toggle in simulator (Settings > Accessibility > Display & Text Size > Reduce Transparency) — grain must disappear on all surfaces

**Checkpoint**: Grain adds character without reducing readability. Accessibility respected.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Fix remaining hardcoded styles, verify consistency, update documentation

- [x] T032 Fix `.foregroundStyle(.secondary)` in `Kiln/Views/Templates/TemplateEditorView.swift` (line 28) to use `DesignSystem.Colors.textSecondary`
- [x] T033 Verify `Kiln/Views/Templates/TemplateExerciseRow.swift` renders correctly with fire theme — update any system colors to design system tokens
- [x] T034 Run `xcodegen generate` to regenerate project with updated `project.yml` (UIUserInterfaceStyle), then build in Xcode to verify zero warnings
- [x] T035 Walk through all screens in simulator verifying: no dark theme remnants, grain visible, warm shadows on all cards, text legible, tab bar dark warm
- [x] T036 Spot-check WCAG AA contrast ratios: `textPrimary` (#1A1A1A) on `background` (#F5F0EB), `textSecondary` (#6B5B4F) on `background`, `textOnPrimary` (#FFF) on `primary` (#C44D22) — all >= 4.5:1 for body text. Primary darkened from #D4592A to #C44D22 to pass.
- [x] T037 Update `CLAUDE.md` if any architectural decisions changed (accent color description, design system structure)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (noise asset) from Setup — BLOCKS all view work
- **US1 (Phase 3)**: Depends on Phase 2 completion (design tokens + grain modifier)
- **US2 (Phase 4)**: Depends on Phase 2 completion. Can run in parallel with US1.
- **US3 (Phase 5)**: Depends on Phase 2 completion. Can run in parallel with US1/US2.
- **US4 (Phase 6)**: Depends on Phase 2 completion. Can run in parallel with US1–US3.
- **US5 (Phase 7)**: Depends on Phase 2 completion. Can run in parallel with US1–US4.
- **US6 (Phase 8)**: Depends on US1 (background grain) and US2 (card structure with shadows). Run after Phases 3–4.
- **Polish (Phase 9)**: Depends on all user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Independent after Foundational
- **US2 (P1)**: Independent after Foundational
- **US3 (P2)**: Independent after Foundational
- **US4 (P2)**: Independent after Foundational
- **US5 (P2)**: Independent after Foundational
- **US6 (P3)**: Depends on US1 + US2 (grain on backgrounds and cards must exist first)

### Within Each User Story

- Background changes before card changes
- Shadows require `.compositingGroup()` before `.shadow()`
- Hardcoded color fixes can be done alongside other changes to the same file

### Parallel Opportunities

- T002 + T003 can run in parallel (different files)
- T004 + T005 + T006 can run in parallel (all in DesignSystem.swift — but same file, so sequential)
- T008–T012 can run in parallel (different view files, all applying same pattern)
- T013 + T014 + T015 can run in parallel (different card view files)
- T017 + T018 + T019 can run in parallel (different view files)
- T024 + T025 + T026 can run in parallel (different view files)
- T027 + T028 + T029 can run in parallel (different card view files)

---

## Parallel Example: User Story 1 (Backgrounds)

```
# After Phase 2 is complete, launch all background updates in parallel:
Task: T008 — Update StartWorkoutView.swift with .grainedBackground()
Task: T009 — Update HistoryListView.swift with .grainedBackground()
Task: T010 — Update WorkoutDetailView.swift with .grainedBackground()
Task: T011 — Update ProfileView.swift with .grainedBackground()
Task: T012 — Update ActiveWorkoutView.swift with .grainedBackground()
```

## Parallel Example: User Story 2 (Card Shadows)

```
# After T013 (TemplateCardView) establishes the card shadow pattern:
Task: T014 — Update WorkoutCardView.swift with card shadows
Task: T015 — Update ExerciseCardView.swift with card shadows
```

---

## Implementation Strategy

### MVP First (US1 + US2 — Both P1)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T007)
3. Complete Phase 3: US1 — backgrounds + grain (T008–T012)
4. Complete Phase 4: US2 — card shadows + tactile feel (T013–T015)
5. **STOP and VALIDATE**: App should now show fire light theme with warm cards — the core visual identity is complete

### Incremental Delivery

1. Setup + Foundational → Design tokens ready
2. US1 + US2 → Core visual identity (MVP)
3. US3 → Tab bar grounded
4. US4 → Active workout themed
5. US5 → History/Profile complete
6. US6 → Grain polish on cards
7. Polish → Final verification and documentation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All color changes flow through DesignSystem.swift — view files just reference tokens
- The grain modifier (`GrainedBackground`) is created once in Phase 2 and reused across all screens
- Many view files will "just work" after the DesignSystem palette rewrite since they already reference tokens — but each still needs visual verification and potential shadow/grain additions
- Stop at any checkpoint to validate story independently
