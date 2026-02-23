# Data Model: Visual Redesign — Fire Theme

**Branch**: `002-visual-redesign` | **Date**: 2026-02-22

This feature is purely cosmetic — no SwiftData model changes. The "data model" for this feature is the design token system.

## Design Tokens

### Color Palette

| Token | Type | Value | Usage |
|-------|------|-------|-------|
| `primary` | Color | Ember orange-red (#D4592A) | Buttons, active states, icons, chart bars |
| `secondary` | Color | Warm brown (#8B4513) | Secondary accents, metadata |
| `background` | Color | Warm cream (#F5F0EB) | Screen backgrounds |
| `surface` | Color | White (#FFFFFF) | Cards, elevated containers |
| `surfaceSecondary` | Color | Light warm gray (#EDE5DD) | Metadata pills, secondary surfaces |
| `textPrimary` | Color | Near-black (#1A1A1A) | Headings, body text |
| `textSecondary` | Color | Warm gray-brown (#6B5B4F) | Labels, captions, secondary text |
| `textOnPrimary` | Color | White (#FFFFFF) | Text on primary-colored buttons |
| `success` | Color | Amber/gold (#C4873A) | Completed set indicators |
| `destructive` | Color | Dark red (#C0392B) | Discard/delete actions |
| `timerActive` | Color | Ember orange-red (#D4592A) | Timer progress ring |
| `timerBackground` | Color | Warm peach (#FDE8D8) | Timer container background |
| `tabBar` | Color | Dark warm brown (#2C1810) | Tab bar background |
| `tabInactive` | Color | Muted warm gray (#9E8E82) | Inactive tab icons |

### Shadow Styles

| Token | Type | Attributes | Usage |
|-------|------|------------|-------|
| `cardShadow` | Shadow | color: brown/0.12, radius: 8, y: 4 | Template cards, workout cards, exercise cards |
| `elevatedShadow` | Shadow | color: brown/0.18, radius: 16, y: 8 | Sheets, modals, floating elements |

### Grain Texture

| Token | Type | Attributes | Usage |
|-------|------|------------|-------|
| `grainOpacity` | CGFloat | 0.05 | Opacity for noise tile overlay |
| `grainBlendMode` | BlendMode | .overlay | Blend mode for noise overlay |

### Corner Radii (existing, consolidated)

| Token | Type | Value | Usage |
|-------|------|-------|-------|
| `cardRadius` | CGFloat | 12 | Cards, section containers |
| `buttonRadius` | CGFloat | 10 | Action buttons |
| `chipRadius` | CGFloat | Capsule | Metadata pills, start buttons |

## Relationships

```
DesignSystem
├── Colors (14 tokens — expanded from 8)
├── Shadows (2 styles — new)
├── Grain (2 tokens — new)
├── CornerRadius (3 tokens — new, consolidating hardcoded values)
├── Typography (4 tokens — unchanged)
├── Spacing (7 tokens — unchanged)
└── Icon (10 tokens — unchanged)
```

## State Transitions

N/A — no stateful entities change. This is a static visual redesign.

## Validation Rules

- All text on `background` (#F5F0EB) must have contrast ratio >= 4.5:1 (body) / 3:1 (large)
- All text on `surface` (#FFFFFF) must have contrast ratio >= 4.5:1 (body) / 3:1 (large)
- `textOnPrimary` (#FFFFFF) on `primary` (#D4592A) must have contrast ratio >= 4.5:1
- Grain overlay must be invisible when `accessibilityReduceTransparency` is true
