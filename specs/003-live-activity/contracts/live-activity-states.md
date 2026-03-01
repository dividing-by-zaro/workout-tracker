# UI Contract: Live Activity Lock Screen States

**Feature**: 003-live-activity
**Date**: 2026-03-01

The Live Activity has three distinct visual states on the lock screen. Only one state is shown at a time.

---

## State 1: Set View (rest timer NOT active)

Shown when there is an incomplete set to complete.

```
┌─────────────────────────────────────────────────┐
│  Bench Press (Barbell)           Set 2 of 4     │
│  Exercise 1 of 5             ⏱ 12:34           │
│                                                  │
│  PREVIOUS          WEIGHT          REPS          │
│  55 lbs x 8                                      │
│                                                  │
│   [−]    55    [+]     [−]    8    [+]           │
│                                                  │
│            [ 🔥 Complete Set ]                   │
└─────────────────────────────────────────────────┘
```

**Elements**:
- Exercise name + equipment type (top-left)
- Set N of M (top-right)
- Exercise position + elapsed time (second row)
- Previous set data label
- Weight value with −/+ buttons (if equipment tracks weight)
- Reps value with −/+ buttons (if equipment tracks reps)
- Complete Set button (primary action)

**Equipment type variations**:
- **weightReps** (barbell, dumbbell, etc.): Shows weight + reps fields (as above)
- **repsOnly**: Shows only reps field, no weight
- **duration**: Shows seconds field with ±5 increment
- **distance**: Shows distance field with ±0.1 increment
- **weightDistance**: Shows weight + distance fields

---

## State 2: Timer View (rest timer active)

Shown after completing a set while the rest countdown is running.

```
┌─────────────────────────────────────────────────┐
│  Bench Press (Barbell)           Set 3 of 4     │
│  Exercise 1 of 5             ⏱ 14:02           │
│                                                  │
│                   1:45                           │
│               ━━━━━━━━━━━━━                      │
│                  REST                            │
│                                                  │
│              [ Skip Rest ]                       │
└─────────────────────────────────────────────────┘
```

**Elements**:
- Exercise name (same as set view — shows the NEXT exercise/set to come)
- Next set position (what's coming after rest)
- Elapsed workout time
- Large countdown timer (auto-updating via `Text(timerInterval:)`)
- Progress bar
- "REST" label
- Skip Rest button

**On timer expiry**:
- `AlertConfiguration(sound: .default)` plays system notification sound
- State transitions to Set View with the next incomplete set
- Or transitions to Complete View if no sets remain

---

## State 3: Complete View (all sets done)

Shown when every set in every exercise is marked complete.

```
┌─────────────────────────────────────────────────┐
│                                                  │
│              🔥 All Sets Complete                │
│                                                  │
│              Legs A  •  45:12                    │
│                                                  │
│          Tap to open app and finish              │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Elements**:
- Completion indicator
- Workout name + total elapsed time
- Instruction to open app (tapping the Live Activity opens via `widgetURL`)

---

## Interaction Model

| User Action | Live Activity State | App Response |
|------------|-------------------|--------------|
| Tap +/− weight | Set View | Adjust current set's weight by ±1 lb (or ±0.1 distance, ±5 seconds) |
| Tap +/− reps | Set View | Adjust current set's reps by ±1 |
| Tap Complete Set | Set View | Mark set complete, start rest timer, transition to Timer View |
| Tap Skip Rest | Timer View | Stop timer, advance to next set, transition to Set View or Complete View |
| Timer reaches 0:00 | Timer View | Play sound, advance to next set, transition to Set View or Complete View |
| Tap anywhere (not a button) | Any state | Open app via `widgetURL("kiln://active-workout")` |

## Design Tokens (from DesignSystem)

| Token | Value | Usage |
|-------|-------|-------|
| primary | #BF3326 | Complete button, timer accent, fire icon |
| background | #F5F0EB | Live Activity background tint |
| textPrimary | #1A1A1A | Exercise name, weight/reps values |
| textSecondary | #6B5B4F | Labels (PREVIOUS, WEIGHT, REPS), elapsed time |
| timerBackground | #FDE8D8 | Timer view progress bar background |
| surface | #FFFFFF | Button backgrounds |
| destructive | #94291F | Skip rest text |
