# Kiln — Design System

> *"You're firing yourself in the kiln and becoming hard as a brick."*

This document captures the visual language for **Kiln**, a personal workout tracker. The system is rooted in a pottery / fired-clay metaphor: warm earth tones, brick textures, and a journal-like editorial register. It's designed to feel calm and considered — a personal training log, not a clinical fitness app.

The "Current Workout" screen is the primary canvas where this system is exercised most fully. Other views (History, Exercises, Profile, etc.) should follow the same vocabulary so the app reads as one coherent thing.

---

## 1. Design principles

1. **Warm, never sterile.** Backgrounds are toned parchment. Pure white is reserved for elevated surfaces.
2. **Type carries the brand.** Three families do most of the work: a wide-set serif for display, a humanist serif for italic body notes, a neutral sans for UI, and a mono for numerics.
3. **The brick metaphor is *literal* on completion.** A done set is rendered as a fired-clay brick — gradient, mortar speckle, drop shadow — laid into a running-bond wall. This is the single most distinctive moment in the app; everything else stays quiet so it can sing.
4. **Containment over highlight.** The previous version used a parchment "highlight" that overflowed the row. Kiln replaces that with self-contained brick rows that have intrinsic edges — they don't leak.
5. **Numbers are tabular.** Every numeric value uses `font-variant-numeric: tabular-nums` so weights and reps align across rows.

---

## 2. Color tokens

All values are sRGB hex (or rgba). The palette is warm-neutral with a single fired-clay accent family.

### 2.1 Surfaces

| Token | Value | Usage |
|---|---|---|
| `--bg` | `#F2EDE3` | App background where no brick pattern is desired (e.g. modals, sub-views) |
| `--bg-deeper` | `#E8DFCE` | Brick-wall pattern fill (the "mortar" tone behind drawn bricks) |
| `--card` | `#FFFFFF` | Elevated surfaces — exercise cards, tab bar, inputs |
| `--card-edge` | `rgba(0,0,0,0.06)` | 1px border on cards |
| `--hair` | `rgba(0,0,0,0.06)` | Internal dividers, dashed borders on pending rows |
| `--mortar` | `#E8DDC9` | Rest-timer fill (warmer than the parchment) |

### 2.2 Ink (text)

| Token | Value | Usage |
|---|---|---|
| `--ink` | `#1B1612` | Primary text, titles, input values |
| `--ink-2` | `#5C544A` | Secondary text, body copy |
| `--ink-3` | `#9A9089` | Tertiary text, labels, helper copy |

### 2.3 Brick (the accent family)

| Token | Value | Usage |
|---|---|---|
| `--brick-1` | `#B8543A` | Brick top (gradient start), "Firing" indicator dot, primary brick accent |
| `--brick-2` | `#9C3E26` | Brick bottom (gradient end), tabbar active text |
| `--brick-shade` | `#7A2D18` | 1px hard-shadow under bricks (mortar line) |
| `--accent` | `#C26B3F` | Reserved for secondary accents (e.g. orange CTA), use sparingly |
| `--red` | `#B43B2E` | Destructive — End button, Skip text |

Bricks are always rendered as **a vertical gradient from `--brick-1` → `--brick-2`**, with a `0 1px 0 --brick-shade, 0 2px 4px rgba(122,45,24,.18)` shadow to simulate the mortar line + ambient depth.

### 2.4 Tabbar active pill
- Background: `#F4E5D7` (warm parchment, lighter than `--bg-deeper`)
- Text: `--brick-2`

---

## 3. Typography

Kiln uses **four** type families, each with a clear job. Don't introduce more.

| Role | Family | Notes |
|---|---|---|
| **Display** | `Instrument Serif` | The workout title and exercise names. 400 weight only. Set tight (`letter-spacing: -0.6` on large display, `-0.3` on section headers). High contrast vertical stress; reads like a book chapter. |
| **Serif (italic)** | `Fraunces`, fallback Georgia | Used **only italic**. Session note, exercise note, "Session no." eyebrow. Adds a hand-written, journal feel. |
| **Sans** | `Inter` | All UI chrome — buttons, labels, header pills, tab bar, secondary copy. Weights 400/500/600/700. |
| **Mono** | `JetBrains Mono` | All numerics — weights, reps, "prev" lines, timers, set indices. Tabular by default. |

### 3.1 Type scale

| Style | Family | Size / weight / tracking |
|---|---|---|
| Workout title (H1) | Instrument Serif | 34 / 400 / `-0.6` / line-height 1 |
| Exercise name (H2) | Instrument Serif | 22 / 400 / `-0.3` / line-height 1.1 |
| Session eyebrow | Fraunces italic | 11 / 500 / `letter-spacing: 2` / UPPERCASE |
| Section labels (e.g. "FIRING", "COOLING") | Inter | 9–10 / 700 / `letter-spacing: 1.2–1.5` / UPPERCASE |
| Body / placeholder note | Fraunces italic | 13 |
| UI buttons | Inter | 13 / 600 |
| Muted helper (`120s`, `4 exercises`) | Inter or Mono | 11–12 / 500 |
| Set index (`01`) | JetBrains Mono | 10 / 700 / `letter-spacing: 1.2` / tabular |
| `prev 25 lb × 10` | JetBrains Mono | 11 / 400 / tabular |
| Rest timer numerals | JetBrains Mono | 22 / 700 / `letter-spacing: -0.4` / tabular |
| Brick weight/reps | JetBrains Mono | 15 / 700 / `letter-spacing: -0.3` / tabular |

### 3.2 Italic placeholder pattern

The session note and exercise note use the same pattern:

> *A note for today's session…*
> Plate-loaded · *Furthest arm setting*

When empty, the text is `--ink-3`. When written, it becomes `--ink-2`. Always Fraunces italic. **No edit-pencil icon** — the italic typography is the affordance.

For the **per-exercise** note, the note sits inline next to the equipment subtitle, separated by a middle-dot:

```
Plate-loaded  ·  Furthest arm setting
```

Both pieces are 12px, but the equipment subtitle uses Inter regular (`--ink-3`) while the note uses Fraunces italic.

---

## 4. The brick wall background

The app's signature texture. Used on the Current Workout screen behind the exercise cards.

### 4.1 Pattern

A **running-bond brick wall**, rendered as an inline SVG dataURI tiled at `60×30 px`:

- Each brick is `30 × 15`.
- Row 1 (y: 0–15): vertical mortar joints at `x = 0, 30, 60`.
- Row 2 (y: 15–30): vertical mortar joints at `x = 15, 45` (offset by half-brick).
- Mortar lines: `1px stroke, rgba(60,40,25,0.13)`.
- Tile fill: `--bg-deeper` (`#E8DFCE`).

```js
const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='60' height='30' viewBox='0 0 60 30'>
  <rect width='60' height='30' fill='#E8DFCE'/>
  <g stroke='rgba(60,40,25,0.13)' stroke-width='1' fill='none' stroke-linecap='square'>
    <path d='M0 0 H60 M0 15 H60 M0 30 H60'/>      <!-- horizontal mortar -->
    <path d='M0 0 V15 M30 0 V15 M60 0 V15'/>      <!-- row 1 verticals -->
    <path d='M15 15 V30 M45 15 V30'/>             <!-- row 2 verticals (offset) -->
  </g>
</svg>`;
// tile at backgroundSize: '60px 30px'
```

This pattern is **decorative**, not structural — exercise cards float on top of it.

### 4.2 When to use it

- ✅ Current Workout screen
- ✅ Workout-in-progress live activity backgrounds
- ⚠️ Use on hero / empty-state moments only on other screens. Most screens (History, Exercises, Profile) should use plain `--bg` so the texture stays special.

---

## 5. Layout system

### 5.1 Page rhythm

```
┌──────────────────────────────┐
│ status bar (transparent)     │
│                              │
│ Header zone (transparent)    │  ← over brick texture
│   eyebrow row                │
│   title + actions            │
│   italic note                │
│                              │
│ ▓▓▓▓▓▓▓▓▓ brick wall ▓▓▓▓▓▓▓▓ │
│                              │
│ ┌────[ Exercise card ]─────┐ │  ← white, r:14
│ │                          │ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│ ┌────[ Exercise card ]─────┐ │
│ └──────────────────────────┘ │
│                              │
│ ┌─[  Workouts | History  ]─┐ │  ← floating tab bar
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

### 5.2 Spacing & radii

Consistent 4-px scale; common values:

| Token | Value |
|---|---|
| Page horizontal padding (header) | 18 px |
| Card outer margin | 14 px (left/right) |
| Card inner padding | 14 / 12 px (top / sides) |
| Card → card vertical gap | 12 px |
| Card border-radius | 14 px |
| Brick row border-radius | 4 px |
| Tab bar border-radius | 14 px |
| Pill border-radius | 999 px (fully rounded) |

### 5.3 Cards

Standard exercise card:

```css
background: #FFFFFF;
border: 1px solid rgba(0,0,0,0.06);
border-radius: 14px;
box-shadow: 0 1px 2px rgba(0,0,0,0.02);
padding: 14px 12px 10px;
margin: 12px 14px 0;
```

Cards always have a **subtle** shadow — they should look like sheets of paper resting on the brick wall, not floating dramatically.

---

## 6. The set row system

There are three states a set can be in:

| State | Visual |
|---|---|
| **Pending** (not yet done) | White card with dashed border, 1.5px black underline inputs |
| **Done** (completed) | Fired-clay brick — gradient fill, white text, mortar shadow, staggered |
| **Resting** (between sets) | Mortar-tone bar with circular timer ring |

All three live in the same vertical stack inside the exercise card, separated by `4px gap`.

### 6.1 Pending set row

```
┌─────────────────────────────────────┐  (1px dashed --hair, r:4)
│ 01  prev 25 lb × 10    25 lb   ×10  │  (white)
└─────────────────────────────────────┘
```

- Grid: `14px 1fr 60px 50px`, `gap: 10px`, padding `10px 12px`.
- Inset from card edges: `marginLeft: 8, marginRight: 8`. (Same as bricks — see § 6.2.)
- Inputs are fields with a 1.5px black underline (`borderBottom: 1.5px solid --ink`), no box. This makes them feel like writing on a page rather than typing into a box.

### 6.2 Done set row — *the brick*

This is the centerpiece. A brick is a gradient-filled, full-bleed-but-inset row:

```css
background: linear-gradient(180deg, #B8543A 0%, #9C3E26 100%);
border-radius: 4px;
padding: 10px 12px;
color: #FBE8DA;
box-shadow: 0 1px 0 #7A2D18, 0 2px 4px rgba(122,45,24,0.18);
position: relative; overflow: hidden;
```

**Mortar speckle overlay** — a radial-gradient dot pattern, 12% opacity, gives the brick a clay grain:

```css
position: absolute; inset: 0; opacity: 0.12; pointer-events: none;
background-image: radial-gradient(rgba(0,0,0,0.5) 0.6px, transparent 0.7px);
background-size: 5px 5px;
```

**Grid:** `14px 1fr auto auto`, `gap: 10px`. The set index, "prev" line, weight, and reps cells.
- **Crucial:** the weight cell uses `white-space: nowrap` so `25 lb` never wraps onto two lines. Same for the reps cell.

#### 6.2.1 The shifting / stagger baseline (read this carefully — got it wrong twice)

A real running-bond wall has alternating rows shifted in *opposite directions* so the wall reads **centered** as a whole. Earlier attempts shifted bricks only to the right, which drifted the whole wall toward the card's right edge.

**Solution:**
1. Inset bricks from the card edge by a base **`INSET = 8px`** on both sides.
2. Each brick gets a **signed `offset`** in pixels — positive shifts right, negative shifts left.
3. Apply offset as `marginLeft: INSET + offset; marginRight: INSET - offset`. The two margins always sum to `2 * INSET = 16px`, so total horizontal space consumed is constant.
4. Use the offset pattern `[-7, +7, -7, +7, …]` so adjacent bricks alternate around the centerline.

```js
const INSET = 8;
const offsets = [-7, +7, -7, +7, -7];

// per-brick:
style={{
  marginLeft: INSET + offset,
  marginRight: INSET - offset,
  // ...
}}
```

This produces a true running-bond effect where each brick is offset ~7px from its neighbor in alternating directions, and the wall stays visually centered in the card.

**Pending rows use `marginLeft: 8, marginRight: 8`** so they stack flush with the centered brick wall.

#### 6.2.2 Brick contents

```
┌───────────────────────────────────────────┐
│ 01   prev 25 lb × 10    25 lb         ×10 │
└───────────────────────────────────────────┘
```

- **Set index** — Mono 10/700, `--ink` on white but `rgba(255,255,255,0.7)` inside a brick (use `opacity: 0.7` on `#FBE8DA`).
- **`prev 25 lb × 10`** — Mono 11/400, `opacity: 0.7`.
- **Weight** — Mono 15/700. The unit (`lb`) is `opacity: 0.5, fontWeight: 400`.
- **Reps** — Mono 15/700, prefixed with literal `×`. `min-width: 32, text-align: right`.

### 6.3 Rest timer ("Cooling")

Sits inside the exercise card, at the position of the next pending set. Same width/inset as a brick.

```css
background: #E8DDC9;          /* --mortar */
border: 1px solid rgba(184,84,58,0.25);
border-radius: 4px;
padding: 10px 12px;
```

Layout: a 28×28 SVG progress ring on the left, then the label/timer stack:

```
○ COOLING                       Skip
  1:59
```

- **Label**: "COOLING" — Inter 9/700, `letter-spacing: 1.4`, UPPERCASE, `--brick-2`.
- **Time**: Mono 22/700, `letter-spacing: -0.4`, `line-height: 1`, `--ink`.
- **Skip**: text-button, Inter 13/600, `--red`.
- **Ring**: two concentric circles — base `rgba(184,84,58,0.2)` 2.5px, foreground `--brick-1` 2.5px with `stroke-dasharray="69" stroke-dashoffset` driven by remaining time. `transform: rotate(-90deg)` so it starts at 12 o'clock.

The terminology — "Firing" while exercising, "Cooling" while resting — is the brand voice. It's small and only appears in these two places, but it's what makes the kiln metaphor feel consistent rather than decorative.

---

## 7. Header anatomy

The Current Workout header sits over the brick texture, transparent.

```
SESSION NO.                          ● FIRING | 0:02
142
                                  ┌─┐ ┌─┐ ┌─────┐
Full Body B                       │+│ │↕│ │█ End│
                                  └─┘ └─┘ └─────┘

A note for today's session…
```

### 7.1 Eyebrow row
- **"SESSION NO. 142"** — Fraunces italic 11/500, `letter-spacing: 2`, UPPERCASE, `--ink-3`. Two lines, "no." on the same line as "SESSION", number wraps below.
- **Firing pill** — see § 7.3.

### 7.2 Title row
- **Workout name** — Instrument Serif 34/400, `--ink`, `letter-spacing: -0.6`, `line-height: 1`.
- **Action buttons** (right side, in order):
  - `+` (add exercise) — 34×34 white square, r:8, `1px solid --card-edge`.
  - `↕` (reorder) — same.
  - `End` — `--red` background, white text, r:8, padding `8px 14px`, with a 6×6 white square as a "stop" glyph on the left.

### 7.3 Firing pill (live indicator)

```css
display: flex; align-items: center; gap: 6px;
padding: 4px 10px;
background: rgba(184,84,58,0.10);
border-radius: 999px;
```

Contents:
1. **Status dot** — 6×6 circle, `--brick-1`, with a `0 0 0 3px rgba(184,84,58,0.18)` glow ring.
2. **"FIRING"** — Inter 10/700, `letter-spacing: 1.4`, UPPERCASE, `--brick-2`.
3. **Divider** — 1×9 vertical bar, `rgba(184,84,58,0.3)`.
4. **Time** — Mono 11/600, tabular, `--brick-2`.

This pill replaces a separate "elapsed time" label — the live indicator and the timer live in the same chip.

### 7.4 Session note

`Fraunces italic 14, --ink-3, line-height: 1.4, margin-top: 10`. Tappable. When written, becomes `--ink-2`.

---

## 8. Tab bar (floating)

```css
position: absolute; bottom: 18; left: 14; right: 14;
background: rgba(255,255,255,0.94);
backdrop-filter: blur(20px);
border: 1px solid rgba(0,0,0,0.06);
border-radius: 14px;
padding: 6px;
box-shadow: 0 10px 30px rgba(0,0,0,0.08);
display: flex;
```

- 4 equal-width tabs.
- Active tab: `#F4E5D7` background pill (r:10), text `--brick-2`.
- Inactive: text `--ink-3`.
- Each tab is a vertical stack: 20×20 icon + label, gap 2.
- Label is Inter 10/600.

Icons are simple stroke-2 SVGs. Don't introduce filled or duotone variants.

---

## 9. Live Activity (lock-screen banner)

The Live Activity surfaces the workout on the lock screen so the user can complete sets and watch rest timers without unlocking. Layout target is **the iOS Live Activity banner** at roughly `360 × 100–120` pt, pinned ~70pt from the bottom of the lock screen.

There are **two states**: **Active** (entering a set) and **Rest** (timer counting down).

### 9.1 Card shell

```css
background: #FFFFFF;
border-radius: 16px;
padding: 12px 14px;
border: 1px solid rgba(0,0,0,0.06);
box-shadow: 0 8px 24px rgba(0,0,0,0.18), 0 1px 3px rgba(0,0,0,0.08);
```

The card is pure white (not parchment) — on a lock-screen wallpaper, white reads as "system surface" and parchment looks dingy. The wallpaper provides all the warmth; the card is the legible plate on top.

The shadow is heavier than in-app cards (`0 8px 24px`) because the card is floating over arbitrary wallpapers, not over a brick wall.

### 9.2 Active state

```
┌──────────────────────────────────────────────┐
│ Squat (Barbell)                  ╔══Done══╗  │  ← title row
│                                  ╚════════╝  │
│                                              │  ← 14px gap
│ 65 × 10  85 × 8  95 × 6  95 × 6  95 × 6  …  │  ← history
│                                              │
│ ┌────────────────┐ ┌────────────────┐        │
│ │−  WEIGHT     +│ │−    REPS     +│        │  ← steppers
│ │   65 lbs      │ │      10       │        │
│ └────────────────┘ └────────────────┘        │
└──────────────────────────────────────────────┘
```

**Title row** — flex, `space-between`, `align-items: center`, `gap: 12`.
- **Title** — Instrument Serif 22 / 400, `letter-spacing: -0.3`, `--ink`. Truncates with ellipsis if it doesn't fit (`overflow: hidden; text-overflow: ellipsis; white-space: nowrap`).
- **Done button** — *brick button* (see § 9.5). `72 × 32`, label "Done".

**Spacer** — `margin-top: 14` between title row and history line.

**History line** — wraps onto multiple lines if needed. Compact format `65 × 10` (no "lbs" — saves space). The current-set entry is tinted `--brick-2` and bold-weight; others are `--ink-3`/medium. Each entry is `whiteSpace: nowrap` so `95 × 6` never breaks across lines. See § 9.4 for overflow behavior.

**Steppers** — flex, `gap: 8`, two equal-width bins. Each:
```css
flex: 1; padding: 6px 8px;
background: #FAF6EE;            /* warm cream, distinct from card */
border: 1px solid rgba(0,0,0,0.06);
border-radius: 10px;
display: flex; align-items: center; justify-content: space-between;
```
- **− / +** buttons — `22 × 22 round, white, 1px hair border, --ink-2 glyph`. Plain neutral; **not red** like the existing implementation. Red on a stepper signals "destructive" and is wrong for value adjustment.
- **Label** — Inter 8 / 700 / `letter-spacing: 1.2` / UPPERCASE / `--ink-3`. e.g. "WEIGHT", "REPS".
- **Value** — Mono 16 / 700 / tabular-nums / `--ink`. Unit (`lbs`) trails at Inter 9 / 600 / `--ink-3`.

### 9.3 Rest state

```
┌──────────────────────────────────────────────┐
│ Squat (Barbell)                       Skip   │  ← title row
│                                              │
│ 65 × 10  85 × 8  95 × 6  95 × 6  95 × 6  …  │  ← history (current = brick-2)
│                                              │
│ 1:58                                         │  ← timer, mono 38/700
│ ▰────────────────────────────────────────    │  ← progress bar
└──────────────────────────────────────────────┘
```

- Same title row structure, but the right-hand action becomes **"Skip"** as a text button:
  ```css
  background: transparent; border: none; padding: 0;
  font: 700 13px Inter; color: --brick-2;
  ```
- History row identical to active state, but `currentIdx` points at the just-completed set.
- **Timer** — Mono 38 / 700 / `letter-spacing: -0.8` / tabular-nums / `--ink`. Format `M:SS` always.
- **Progress bar** — 4px tall, `--hair` track, brick gradient fill (`90deg, --brick-1, --brick-2`). Width = `elapsed / total * 100%`. So `2 sec into 2:00 = 4% wide`.

### 9.4 History row overflow

The history row in a tight Live Activity will often overflow. Behavior:

1. **Try to fit** all sets on one line (compact `65 × 10` format).
2. **If wider than card**, **wrap** to a second line using `flex-wrap: wrap`. This is fine — even three lines reads well at 12px / `line-height: 1.5`.
3. **Never** truncate or hide entries. The user wants to see the prescription. Wrapping is preferred over an ellipsis.
4. **Never** scroll horizontally inside a Live Activity — it's not interactive that way on the lock screen.

If a workout has so many sets that 3 lines aren't enough, **collapse repeated identical sets**: `65 × 10  85 × 8  95 × 6 ×5` (read "5 sets of 95 × 6"). Use a thinner mono `×N` suffix in `--ink-3`.

### 9.5 The brick button

This is the single most important visual decision in the Live Activity — it replaces the rounded red "Done" pill that prompted this redesign. It's a real fired-clay brick, miniaturized:

```css
width: 72; height: 32; padding: 0;
background: linear-gradient(180deg, #B8543A 0%, #9C3E26 100%);
border: none;
border-radius: 4px;       /* sharp, like a brick */
color: #FBE8DA;
font: 700 13px Inter; letter-spacing: 0.2;
box-shadow:
  0 1px 0 #7A2D18,                /* hard mortar shadow under */
  0 2px 4px rgba(122,45,24,0.18); /* ambient depth */
```

**Speckle overlay** (gives the clay grain): an absolutely-positioned `::before` or inner div:
```css
position: absolute; inset: 0; pointer-events: none;
opacity: 0.12;
background-image: radial-gradient(rgba(0,0,0,0.5) 0.6px, transparent 0.7px);
background-size: 5px 5px;
```

**Proportions are deliberate.** A real brick is roughly 2.25:1 (8" × 3.625"). The button is `72:32 ≈ 2.25:1`, matching that ratio so it reads as a brick on sight, not as a generic CTA. Don't square it; don't elongate it past 3:1.

**Tap behavior** — single tap = "lay this brick", which means: complete the current set with whatever weight/reps are showing. No confirmation dialog.

### 9.6 Edge cases

| Scenario | Behavior |
|---|---|
| **First set of the workout** | History row is `prev 65 × 10  prev 85 × 8  …` showing the *previous session's* numbers in `--ink-3`. The currentIdx index is 0 and tinted `--brick-2`. If there's no previous session, show only the current session's slots as faint pending placeholders (`— × —`). |
| **No previous-session data at all** | Skip the history row entirely. Steppers still show the suggested starting values (or empty `0 / 0` if none). Card height collapses to ~85pt. |
| **Very long exercise name** | Title row truncates with single-line ellipsis. Don't allow it to wrap to two lines and push the brick down — that breaks the brick's visual position. |
| **Stepper at zero** | The `−` button greys to `opacity: 0.35` and is non-interactive. Same for `+` at the workout's defined max (if any). |
| **Last set of the exercise** | Brick label changes from "Done" → "Done ✓" with a 9px white check glyph appended. After tapping, the Live Activity transitions to the *next* exercise rather than going to rest, unless the workout dictates rest first. |
| **Last set of the workout** | Brick label becomes "Finish". Tapping ends the workout and dismisses the Live Activity over a 600ms fade. |
| **Rest timer at 0:00** | Card transitions back to Active state for the next set. The transition is a 200ms cross-fade — the timer fades out as the steppers fade in. Don't slide; the card height changes and slides look broken at lock-screen scale. |
| **Rest > 9:59** | Format becomes `MM:SS`. Mono is tabular so the layout doesn't shift. |
| **Network / sync error** | A small `1` red dot appears in the top-right corner of the card; tapping the card opens the app to resolve. Don't surface error text on the lock screen. |
| **User taps the wallpaper outside the card** | No-op. The card is the only interactive surface. |
| **Dark Mode lock screen** | Card stays white. iOS lock-screen widgets traditionally maintain their native palette; trying to invert would lose the warmth that makes this banner feel like Kiln. |
| **Multiple exercises queued ("superset")** | Show the current exercise's title only. Indicate the next exercise via a tiny italic `next: Push-up` line below the steppers in `--ink-3` Fraunces italic 11. Skip if not in a superset block. |
| **User backgrounds during rest** | Timer keeps counting. When it hits 0:00, iOS plays the standard Live Activity update sound and shows a notification ("Cooling complete · Squat (Barbell)"). |

### 9.7 Color reuse vs in-app

The Live Activity uses the **same** tokens as the in-app design — `--brick-1/2`, `--ink/2/3`, `--hair`, `--card`. There is no separate "compact" palette. Two notable choices:

- **No brick-pattern background.** The lock-screen wallpaper is the texture; the card stays clean white.
- **No "FIRING / SET 3 OF 7" eyebrow** in the final design. Originally explored as Direction B's hero, but removed — on the lock screen, the title and the brick CTA are enough to communicate "you're mid-workout, tap to advance." The eyebrow is in-app territory.

### 9.8 What this design replaces

The original implementation had:
- A pill-shaped red "Done" button with an inline flame icon.
- Red ⊖/⊕ stepper controls.
- A "WEIGHT" / "REPS" label split that pushed values too small.

The new design replaces these with:
- A fired-clay **brick** button (the metaphor's atomic unit, not a generic pill).
- **Neutral cream** stepper bins with white `−`/`+` glyphs (red is reserved for *destructive* actions like "End workout").
- **Larger numerals** in mono so the values are the visual anchor of each stepper, not the label.

---

## 10. Voice & microcopy

Kiln has a consistent vocabulary. Use it everywhere:

| Concept | Kiln word | Avoid |
|---|---|---|
| Workout in progress | **Firing** | "Active", "In session" |
| Resting between sets | **Cooling** | "Resting", "Recovery" |
| Add a completed set | **"Lay another brick"** | "Add Set", "+ Set" |
| Workout history entry | **Session no. *N*** | "Workout #N" |
| Note placeholders | "*A note for today's session…*", "*A note for this exercise…*" | Generic "Add note" buttons |

The voice is quietly poetic, not theatrical. Use it in copy and labels; never in body text or instructional UI.

---

## 11. Other views — applying the system

The Current Workout screen exercises the system most fully. Other screens should pull from the same vocabulary:

### History
- Plain `--bg` background (no brick pattern — keep it special).
- Each historical workout is a card matching § 5.3.
- Eyebrow above each card: "*Session no. 141 · Apr 28*" (Fraunces italic).
- Display title: workout name in Instrument Serif.
- Below: a 4–6 brick *thumbnail row* (small bricks, no text, just the gradient/mortar shadow) representing the sets done. This visual echo ties history to the live screen.

### Exercises (library)
- Plain `--bg`.
- Cards r:14, white. Exercise name in Instrument Serif 22.
- Equipment subtitle in Inter 12 `--ink-3`.
- Optional note inline (Fraunces italic) — same pattern as Current Workout.
- List rows separated by `1px solid --hair`; no card-on-card.

### Profile
- Plain `--bg`. Settings rows use `--card` with `--card-edge` borders, r:14.
- All numerics tabular mono — total sessions, total bricks laid, etc.
- Lifetime stats can lean into the metaphor: "**1,284 bricks laid**" rather than "1,284 sets completed".

### Modal / sheets
- White `--card` surface, full-width with rounded top corners (r:24).
- 1px `--hair` divider between header and body.
- Drag handle at top: 36×4 pill, `--ink-3`, opacity 0.4.

### Buttons
- **Primary**: `--ink` background, white text, r:999 OR r:8. Inter 13/600.
- **Destructive**: `--red`, white text. Same shape. Used for End.
- **Brick CTA** (rare — e.g. "Start workout"): `--brick-1` → `--brick-2` gradient, white text, r:8, with the same `0 1px 0 --brick-shade` mortar shadow as a brick row.
- **Tertiary / text**: `--brick-1` text on transparent. Inter 13/600.

---

## 12. Implementation notes for Claude Code

### 12.1 React structure (current implementation)

The design is implemented as a React component tree. Functional components, no state libraries. The Current Workout screen consists of:

```
<V5Screen state="untouched" | "partial">
  └ <V5Header/>
      ├ eyebrow row (SESSION + FIRING pill)
      ├ title row (Full Body B + actions)
      └ session note
  └ <V5Exercise name sub note rest sets showRestAt>
      ├ header (name, sub · note inline, rest, ⋯)
      └ sets stack
          ├ <V5BrickSet idx prev weight reps offset/>   (status: 'done')
          ├ <V5PendingSet idx prev weight reps/>         (status: 'pending')
          └ <V5RestTimer/>                                (when showRestAt === i)
  └ <V5TabBar/>
```

### 12.2 Iconography

All icons are inline stroke-2 SVGs at 11–20px. Don't pull in an icon library; the set is small and stays cohesive when authored by hand.

Required icons (all already implemented in the reference):
- `+` (plus)
- `↕` (reorder)
- ⏱ (clock circle)
- ⋯ (ellipsis)
- 4 tab icons (dumbbell, clock, list, person)

### 12.3 Fonts

```html
<link href="https://fonts.googleapis.com/css2?
  family=Inter:wght@400;500;600;700;800
  &family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,400;1,9..144,500
  &family=Instrument+Serif:ital@0;1
  &family=JetBrains+Mono:wght@400;500;600;700
  &display=swap" rel="stylesheet">
```

### 12.4 Things to *not* do

- ❌ No emoji in product UI.
- ❌ No flame, fire, or ember iconography. The kiln metaphor is carried by *bricks*, not flames.
- ❌ No drop-shadows on cards beyond the subtle `0 1px 2px rgba(0,0,0,0.02)`. Big shadows feel webby.
- ❌ Don't use `transform: translateX` for the brick stagger — use signed margins so the row's bounding box reflects its visual position. (translate breaks layout/measurements and was the source of the earlier overflow bug.)
- ❌ Don't put white-space-wrap-eligible text (`25 lb`) without `white-space: nowrap`. Bricks have tight columns and will break the layout.
- ❌ Don't add icons next to the italic note placeholders. The italic *is* the affordance.

---

## 13. Summary

Kiln is **a journal where each completed set is laid like a brick in a wall**. Warm parchment surfaces, fired-clay accent, wide-set serif display, italic body notes. Numbers are mono and tabular. The metaphor lives most strongly in three places:

1. The brick-pattern background.
2. The fired-clay brick row that replaces a generic "completed" highlight.
3. The vocabulary — *Firing*, *Cooling*, *Lay another brick*, *Session no.*

Carry those three across every view and the system will hold together.
