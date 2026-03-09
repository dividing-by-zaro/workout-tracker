# Bug Fix Plan — Kiln Workout Tracker

## Tier 1: One-liner / Trivial (< 5 lines each)

### Fix 2 — WorkoutEditView "Done" doesn't save
**File:** `Kiln/Views/History/WorkoutEditView.swift:68-69`
**Change:** Add `try? modelContext.save()` before `dismiss()` in the "Done" button action.

### Fix 6 — `totalVolume` counts uncompleted sets
**File:** `Kiln/Models/Workout.swift:21-25`
**Change:** Add `.filter(\.isCompleted)` before the reduce:
```swift
var totalVolume: Double {
    exercises.flatMap { $0.sets }.filter(\.isCompleted).reduce(0.0) { total, set in
        total + (set.weight ?? 0) * Double(set.reps ?? 0)
    }
}
```

### Fix 15 — `lastCompletedSetId` not cleared in `finishWorkout`/`discardWorkout`
**File:** `Kiln/Services/WorkoutSessionManager.swift`
**Change:** Add `lastCompletedSetId = nil` and `cancelBackgroundRestExpiry()` to both `finishWorkout()` (after line 302) and `discardWorkout()` (after line 318). This also fixes **Bug 5** (background rest timer firing after workout ends).

### Fix 16 — `cacheCurrentState()` calls `findCurrentSet()` twice
**File:** `Kiln/Services/WorkoutSessionManager.swift:433-438`
**Change:** Store result in a local:
```swift
private func cacheCurrentState() {
    let state = liveActivityService.buildContentState(from: self)
    let current = findCurrentSet()
    let setId = current?.1.id
    let restDuration = current?.0.exercise?.defaultRestSeconds ?? 120
    LiveActivityCache.cache(state, setId: setId, restDuration: restDuration)
}
```

### Fix 22 — `WorkoutEditView.removeExercise` doesn't re-normalize order
**File:** `Kiln/Views/History/WorkoutEditView.swift:163-166`
**Change:** After delete + save, re-normalize order on remaining exercises:
```swift
private func removeExercise(_ workoutExercise: WorkoutExercise) {
    modelContext.delete(workoutExercise)
    for (i, ex) in workout.sortedExercises.enumerated() {
        ex.order = i
    }
    try? modelContext.save()
}
```

### Fix 23 — WorkoutCardView shows "0 lbs" for cardio workouts
**File:** `Kiln/Views/History/WorkoutCardView.swift:21`
**Change:** Only show volume label when `totalVolume > 0`:
```swift
if workout.totalVolume > 0 {
    Label(String(format: "%.0f lbs", workout.totalVolume), systemImage: "scalemass")
}
```

---

## Tier 2: Small (5–20 lines each)

### Fix 4 — Lock-screen completions lost after crash recovery
**File:** `Kiln/Services/WorkoutSessionManager.swift:59-72`
**Change:** Call `syncCacheToSwiftData()` inside `checkForInterruptedWorkout`, after restoring the workout and setting the model context. The context is already set at line 60, and `activeWorkout` is set at line 68, so add the call after `restTimer.syncFromPersistedState()`:
```swift
func checkForInterruptedWorkout(context: ModelContext) {
    self.modelContext = context
    // ... existing fetch logic ...
    activeWorkout = interrupted
    hasInterruptedWorkout = true
    startElapsedTimer()
    restTimer.syncFromPersistedState()
    syncCacheToSwiftData()  // recover lock-screen completions
}
```

### Fix 7 — `endWorkoutOverlay` runs SwiftData fetch every second
**File:** `Kiln/Views/Workout/ActiveWorkoutView.swift:126-203`
**Change:** Move the diff computation inside the conditional check so it only runs when the overlay is visible. Restructure `endWorkoutOverlay` to:
```swift
private var endWorkoutOverlay: some View {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture { showEndConfirmation = false }

        let diff = sessionManager.computeTemplateDiff(context: modelContext)

        VStack(spacing: DesignSystem.Spacing.md) {
            // ... same content ...
        }
        // ... same styling ...
    }
}
```
And wrap the `.overlay` call site to guard:
```swift
.overlay {
    if showEndConfirmation {
        endWorkoutOverlay
    }
}
```
Wait — the current code already does this. The issue is that `endWorkoutOverlay` is a computed property that computes the diff unconditionally in `let diff = ...` on line 127. The `if showEndConfirmation` on line 67 should prevent the body of `endWorkoutOverlay` from evaluating when `showEndConfirmation == false`. Actually in SwiftUI, the `if` in the `overlay` closure means the computed property IS only called when `showEndConfirmation == true`. Let me re-check...

Actually, SwiftUI evaluates the entire `overlay` closure to build the view tree — the `if` check happens at SwiftUI's view-diffing level, but the closure body still runs. So `endWorkoutOverlay` IS evaluated on every body render. The fix is to move the `if` guard into the `endWorkoutOverlay` property itself, or compute the diff lazily only when shown. Simplest approach: make `diff` a `@State` computed on-demand:

**Revised approach:** Add a `@State private var templateDiff: TemplateDiff?` and compute it only when `showEndConfirmation` becomes true:
```swift
@State private var templateDiff: TemplateDiff?
```
In the "End" button action:
```swift
Button {
    templateDiff = sessionManager.computeTemplateDiff(context: modelContext)
    showEndConfirmation = true
} label: { ... }
```
Then `endWorkoutOverlay` uses `templateDiff` instead of calling `computeTemplateDiff`.

### Fix 9 — Rest timer display freezes during scroll
**File:** `Kiln/Services/RestTimerService.swift:70-77`
**Change:** Add the timer to `.common` RunLoop mode:
```swift
private func startDisplayTimer() {
    displayTimer?.invalidate()
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
        Task { @MainActor in
            self?.tick()
        }
    }
    RunLoop.main.add(timer, forMode: .common)
    displayTimer = timer
}
```

### Fix 11 — `bestSetLabel` wrong for non-weight exercises
**File:** `Kiln/Views/History/WorkoutCardView.swift:59-72`
**Change:** Replace the single `max(by:)` with equipment-type-aware logic:
```swift
private func bestSetLabel(for workoutExercise: WorkoutExercise) -> String {
    let completedSets = workoutExercise.sortedSets.filter(\.isCompleted)
    guard !completedSets.isEmpty else { return "" }
    let category = workoutExercise.exercise?.resolvedEquipmentType?.equipmentCategory ?? "weightReps"

    switch category {
    case "weightReps", "weightDistance":
        guard let best = completedSets.max(by: {
            ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0)
        }) else { return "" }
        if let w = best.weight, let r = best.reps {
            return "\(Int(w)) lb x \(r)"
        }
        return ""
    case "repsOnly":
        guard let best = completedSets.max(by: { ($0.reps ?? 0) < ($1.reps ?? 0) }) else { return "" }
        if let r = best.reps { return "x \(r)" }
        return ""
    case "duration":
        guard let best = completedSets.max(by: { ($0.seconds ?? 0) < ($1.seconds ?? 0) }) else { return "" }
        if let s = best.seconds { return "\(Int(s))s" }
        return ""
    case "distance":
        guard let best = completedSets.max(by: { ($0.distance ?? 0) < ($1.distance ?? 0) }) else { return "" }
        if let d = best.distance { return String(format: "%.1f mi", d) }
        return ""
    default:
        return ""
    }
}
```

### Fix 12 — Chart week boundaries not aligned to calendar weeks
**File:** `Kiln/Views/Profile/WorkoutsPerWeekChart.swift:8-26`
**Change:** Snap `weekStart` to the beginning of the calendar week:
```swift
private var weeklyData: [(week: String, count: Int)] {
    let calendar = Calendar.current
    let now = Date.now
    guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
    var result: [(week: String, count: Int)] = []

    for weeksAgo in (0..<8).reversed() {
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: currentWeekStart) else { continue }
        guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { continue }

        let count = workouts.filter { workout in
            guard let completed = workout.completedAt else { return false }
            return completed >= weekStart && completed < weekEnd
        }.count

        let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
        result.append((week: label, count: count))
    }
    return result
}
```

### Fix 14 — `fullScreenCover` can show blank content
**File:** `Kiln/Views/ContentView.swift:47-56`
**Change:** Capture `celebrationData` before the closure:
```swift
.fullScreenCover(isPresented: Binding(
    get: { sessionManager.celebrationData != nil },
    set: { if !$0 { sessionManager.celebrationData = nil } }
)) {
    // Capture a local copy to avoid the race where celebrationData becomes nil
    // between isPresented triggering and the content closure evaluating
    let data = sessionManager.celebrationData ?? CelebrationData.empty
    CelebrationView(data: data, onDismiss: {
        sessionManager.celebrationData = nil
    })
}
```
This requires adding a static `empty` factory to `CelebrationData` as a fallback. Alternatively, keep the `if let` but add an else clause with an empty view + auto-dismiss:
```swift
.fullScreenCover(isPresented: Binding(
    get: { sessionManager.celebrationData != nil },
    set: { if !$0 { sessionManager.celebrationData = nil } }
)) {
    if let data = sessionManager.celebrationData {
        CelebrationView(data: data, onDismiss: {
            sessionManager.celebrationData = nil
        })
    } else {
        Color.clear.onAppear { sessionManager.celebrationData = nil }
    }
}
```

### Fix 19 — Audio session deactivation cuts off alert sound
**File:** `Kiln/Services/BackgroundAudioService.swift:50-57`
**Change:** Only deactivate the audio session if the alert player is not currently playing:
```swift
func stopSilentAudio() {
    guard isPlaying else { return }
    audioPlayer?.stop()
    audioPlayer = nil
    isPlaying = false

    // Only deactivate session if alert isn't still playing
    if alertPlayer == nil || alertPlayer?.isPlaying != true {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
```

### Fix 24 — Fire-and-forget Tasks for Live Activity updates
**File:** `Kiln/Services/LiveActivityService.swift:23-42`
**Change:** Make `updateActivity` and `endActivity` async so ordering is caller-controlled:
```swift
func updateActivity(
    _ activity: Activity<WorkoutActivityAttributes>,
    state: WorkoutActivityAttributes.ContentState,
    alertConfiguration: AlertConfiguration? = nil
) {
    let content = ActivityContent(state: state, staleDate: nil)
    Task {
        await activity.update(content, alertConfiguration: alertConfiguration)
    }
}
```
Actually, making them `async` would cascade changes through the whole codebase. A simpler fix is to use a serial task queue to guarantee ordering. But the simplest pragmatic fix: these fire-and-forget Tasks are unlikely to race in practice because they're all dispatched from the MainActor synchronously. The real risk is `endActivity` racing with a pending `updateActivity`. Fix: in `endLiveActivity()`, nil out `currentActivity` first to prevent any subsequent `updateLiveActivity` calls:
```swift
private func endLiveActivity() {
    guard let activity = currentActivity else { return }
    currentActivity = nil  // prevent further updates
    let state = liveActivityService.buildContentState(from: self)
    liveActivityService.endActivity(activity, finalState: state)
    LiveActivityCache.clear()
}
```
This is already essentially done (line 417 sets it to nil), but the activity is captured as a local before the nil, so subsequent update calls on other references won't fire. This is actually fine. Downgrade to no-fix-needed. **SKIP this fix.**

---

## Tier 3: Medium (20–50 lines each)

### Fix 1 — Weight/reps edits never saved (data loss on crash)
**File:** `Kiln/Views/Workout/SetRowView.swift`
**Change:** Add a debounced save mechanism. When a `@Bindable` field changes, schedule a save after a short delay. Use an `onChange` modifier with debounce:

In `SetRowView`, add `@Environment(\.modelContext) private var modelContext` and an `onChange` that saves on a debounce. Since SetRowView uses `CustomInputTextField` which calls `syncValue` on every keystroke, the cleanest approach is to add a save trigger in `ExerciseCardView` or at the `ActiveWorkoutView` level.

**Simplest approach:** Add a periodic save in `WorkoutSessionManager` — every time the elapsed timer ticks (every 1 second), also save the context. This piggybacks on the existing timer:
```swift
private func startElapsedTimer() {
    elapsedTimer?.invalidate()
    elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            guard let self, let workout = self.activeWorkout else { return }
            self.elapsedSeconds = Int(Date.now.timeIntervalSince(workout.startedAt))
            try? self.modelContext?.save()
        }
    }
}
```
This saves at most once per second which is very reasonable. The save is a no-op if nothing changed in the context.

### Fix 3 — TemplateEditorView "Cancel" doesn't undo destructive deletes
**File:** `Kiln/Views/Templates/TemplateEditorView.swift`
**Change:** Stop calling `modelContext.delete(te)` in the `.onDelete` handler. Instead, only track deletions locally, and apply them in `saveTemplate()`.

Replace the `.onDelete` handler (lines 39-44):
```swift
.onDelete { indexSet in
    templateExercises.remove(atOffsets: indexSet)
}
```
Remove the `modelContext.delete(te)` call — deletions are handled in `saveTemplate()` where line 93 already deletes exercises not present in `templateExercises`.

For newly inserted exercises (via picker, line 76), stop calling `modelContext.insert(te)` immediately. Instead, just append to the local array. Move the insert to `saveTemplate()`:
```swift
.sheet(isPresented: $showExercisePicker) {
    ExercisePickerView { exercise in
        let te = TemplateExercise(
            order: templateExercises.count,
            defaultSets: 3,
            exercise: exercise
        )
        templateExercises.append(te)
    }
}
```
Then in `saveTemplate()`, insert each `TemplateExercise` into the context there:
```swift
private func saveTemplate() {
    if let existing = existingTemplate {
        existing.name = name
        for ex in existing.exercises where !templateExercises.contains(where: { $0.id == ex.id }) {
            modelContext.delete(ex)
        }
        for (index, te) in templateExercises.enumerated() {
            te.order = index
            te.template = existing
            if te.modelContext == nil {
                modelContext.insert(te)
            }
        }
    } else {
        let template = WorkoutTemplate(name: name)
        modelContext.insert(template)
        for (index, te) in templateExercises.enumerated() {
            te.order = index
            te.template = template
            modelContext.insert(te)
        }
    }
    try? modelContext.save()
}
```

### Fix 8 — PreFillService fetches ALL workouts (performance)
**File:** `Kiln/Services/PreFillService.swift`
**Change:** Add `fetchLimit` to the descriptor. Since workouts are sorted by most recent first and we stop at the first match, we can't truly limit the fetch (the match could be far back). But we CAN restructure to avoid re-fetching on every view render.

**Two-part fix:**

Part A — Cache pre-fill data in `ActiveWorkoutView` so it's not re-computed on every render. Change `buildPreFillData` from a live function call to a `@State` dictionary computed once:
```swift
@State private var preFillCache: [PersistentIdentifier: [PreFillData]] = [:]

// In body, replace the inline call:
let preFill = preFillCache[workoutExercise.persistentModelID] ?? []

// Compute on appear and when exercises change:
.onAppear { buildPreFillCache() }
.onChange(of: workout.exercises.count) { buildPreFillCache() }

private func buildPreFillCache() {
    guard let workout = sessionManager.activeWorkout else { return }
    var cache: [PersistentIdentifier: [PreFillData]] = [:]
    for ex in workout.sortedExercises {
        guard let exercise = ex.exercise else { continue }
        cache[ex.persistentModelID] = PreFillService.preFillSets(for: exercise, setCount: ex.sets.count, in: modelContext)
    }
    preFillCache = cache
}
```

Part B — Same for `WorkoutEditView.buildPreFillData`.

### Fix 13 — SwipeToDelete gesture conflicts with scroll
**File:** `Kiln/Views/Workout/SwipeToDelete.swift:36-59`
**Change:** Increase `minimumDistance` and filter by horizontal dominance:
```swift
.simultaneousGesture(
    DragGesture(minimumDistance: 30)
        .onChanged { value in
            let translation = value.translation
            // Only activate if gesture is predominantly horizontal
            guard abs(translation.width) > abs(translation.height) * 1.5 else { return }
            if translation.width < 0 {
                offset = max(translation.width, -deleteWidth * 1.2)
            } else if showingDelete {
                offset = min(translation.width - deleteWidth, 0)
            }
        }
        .onEnded { value in
            let translation = value.translation
            guard abs(translation.width) > abs(translation.height) * 1.5 else {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    showingDelete = false
                }
                return
            }
            withAnimation(.easeOut(duration: 0.2)) {
                if translation.width < -40 {
                    offset = -deleteWidth
                    showingDelete = true
                } else {
                    offset = 0
                    showingDelete = false
                }
            }
        }
)
```

### Fix 21 — Empty `onOpenURL` handler (deep link does nothing)
**File:** `Kiln/KilnApp.swift:17-20` and `Kiln/Views/ContentView.swift`
**Change:** Add a `@State` selected tab index to `ContentView` and switch to the Workout tab on deep link:
```swift
// ContentView.swift
@State private var selectedTab = 0

TabView(selection: $selectedTab) {
    Group { ... }
    .tabItem { ... }
    .tag(0)

    NavigationStack { HistoryListView() }
    .tabItem { ... }
    .tag(1)

    NavigationStack { ProfileView() }
    .tabItem { ... }
    .tag(2)
}
```
Expose a method or use `@Environment` to let `KilnApp` communicate the tab switch. Simplest: use a published property on `WorkoutSessionManager`:
```swift
// WorkoutSessionManager
var shouldSwitchToWorkoutTab = false
```
In KilnApp:
```swift
.onOpenURL { url in
    sessionManager.shouldSwitchToWorkoutTab = true
}
```
In ContentView:
```swift
.onChange(of: sessionManager.shouldSwitchToWorkoutTab) {
    if sessionManager.shouldSwitchToWorkoutTab {
        selectedTab = 0
        sessionManager.shouldSwitchToWorkoutTab = false
    }
}
```

### Fix 25 — `WorkoutSessionManager` not annotated `@MainActor`
**File:** `Kiln/Services/WorkoutSessionManager.swift:24-25`
**Change:** Add `@MainActor` to the class declaration:
```swift
@MainActor
@Observable
final class WorkoutSessionManager {
```
This will cause build errors wherever the class is accessed from non-MainActor contexts. The intent handlers already use `await MainActor.run { ... }` so those are fine. The `Timer.scheduledTimer` callbacks need adjusting — remove the inner `Task { @MainActor in }` wrappers since the class is now MainActor-isolated. The `static var shared` access from intents already uses `MainActor.run`. This is mostly removing redundant `Task { @MainActor in }` wrappers.

Also add `@MainActor` to `RestTimerService` for consistency.
