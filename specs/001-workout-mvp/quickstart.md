# Quickstart: Workout MVP

**Branch**: `001-workout-mvp` | **Date**: 2026-02-22

## Prerequisites

- Xcode 15+ (with Swift 5.9+)
- iPhone 13 (or Simulator running iOS 17+)
- The `strong_workouts.csv` file (in repo root)

## Build & Run

1. Open `Kiln.xcodeproj` (or `Kiln.xcworkspace` if SPM packages added)
   in Xcode.
2. Select the iPhone 13 simulator (or your physical device).
3. Build and run (Cmd+R).

## First Launch

1. The app opens to the Workout tab with an empty template grid and a
   "Start an Empty Workout" button.
2. Import your Strong data:
   - Navigate to Profile or a settings/import action.
   - Select or share the `strong_workouts.csv` file into the app.
   - Wait for the import to complete. A summary shows rows
     imported vs. skipped.
3. After import:
   - Two templates appear on the Workout tab: "New Legs/full Body A" and
     "New Legs/full Body B".
   - History tab shows all imported workouts.
   - Profile tab shows your name, workout count, and workouts-per-week
     chart.

## Core Workflow: Logging a Workout

1. **Start**: Tap a template card on the Workout tab. The active workout
   view replaces the template grid.
2. **Complete sets**: Each exercise shows set rows pre-filled with your
   previous data. Tap the checkmark to complete a set. The rest timer
   starts automatically.
3. **Modify**: Add exercises, swap exercises, add/remove sets, edit
   weight/reps inline as needed.
4. **Finish**: Tap "Finish Workout" at the bottom. The workout is saved
   and you return to the template grid.

## Timer Behavior

- Rest timer counts down in the active workout view (default: 90 seconds).
- Alerts fire (audio + haptic) even when the app is backgrounded or the
  device is locked — via a scheduled local notification.
- If you complete the next set before the timer finishes, the old timer
  is cancelled and a new one starts.
- Adjust timer duration by tapping the timer display during a workout.

## Crash Recovery

- All set completions are persisted immediately.
- If the app is terminated mid-workout, the next launch restores the
  workout with all previously completed sets intact.
- If a rest timer was running, it recalculates from the saved end time.

## Verification Checklist

- [ ] Import `strong_workouts.csv` and verify all workouts appear in
      History with correct data.
- [ ] Start a workout from "New Legs/full Body A" template — verify
      pre-filled set data matches most recent exercise data.
- [ ] Complete a set — verify checkmark, immediate persistence, rest timer
      starts.
- [ ] Lock the phone during a rest timer — verify notification fires at
      timer end.
- [ ] Force-quit during a workout — relaunch and verify workout is
      restored.
- [ ] Navigate to History/Profile during a workout — verify workout
      continues and tabs display correctly.
- [ ] Finish a workout — verify it appears in History and Profile count
      updates.
- [ ] Create a new template — verify it appears in the template grid and
      can start a workout.
