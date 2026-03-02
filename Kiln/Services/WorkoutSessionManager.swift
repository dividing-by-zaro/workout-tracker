import ActivityKit
import Foundation
import SwiftData
import SwiftUI

@Observable
final class WorkoutSessionManager {
    static var shared: WorkoutSessionManager?

    var activeWorkout: Workout?
    var isWorkoutInProgress: Bool { activeWorkout != nil }
    var elapsedSeconds: Int = 0
    var lastCompletedSetId: UUID?

    let restTimer = RestTimerService()
    let liveActivityService = LiveActivityService()
    let backgroundAudio = BackgroundAudioService()

    private var currentActivity: Activity<WorkoutActivityAttributes>?
    private var modelContext: ModelContext?
    private var elapsedTimer: Timer?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var restExpiryWorkItem: DispatchWorkItem?

    var hasInterruptedWorkout: Bool = false

    init() {
        Self.shared = self
        restTimer.onTimerExpired = { [weak self] in
            self?.handleTimerExpired()
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Crash Recovery

    func checkForInterruptedWorkout(context: ModelContext) {
        self.modelContext = context
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isInProgress == true }
        )
        guard let workouts = try? context.fetch(descriptor),
              let interrupted = workouts.first else {
            return
        }
        activeWorkout = interrupted
        hasInterruptedWorkout = true
        startElapsedTimer()
        restTimer.syncFromPersistedState()
    }

    func resumeInterruptedWorkout() {
        hasInterruptedWorkout = false
        reconnectLiveActivity()
        backgroundAudio.startSilentAudio()
    }

    func discardInterruptedWorkout(context: ModelContext) {
        hasInterruptedWorkout = false
        discardWorkout(context: context)
    }

    // MARK: - Start Workout from Template

    func startWorkout(from template: WorkoutTemplate, context: ModelContext) {
        guard activeWorkout == nil else { return }
        self.modelContext = context

        let workout = Workout(name: template.name, templateId: template.id)
        context.insert(workout)

        for (index, templateExercise) in template.sortedExercises.enumerated() {
            guard let exercise = templateExercise.exercise else { continue }

            let workoutExercise = WorkoutExercise(order: index, exercise: exercise, workout: workout)
            context.insert(workoutExercise)

            let preFillData = PreFillService.preFillSets(for: exercise, setCount: templateExercise.defaultSets, in: context)

            for (setIndex, data) in preFillData.enumerated() {
                let workoutSet = WorkoutSet(
                    order: setIndex,
                    weight: data.weight,
                    reps: data.reps,
                    distance: data.distance,
                    seconds: data.seconds,
                    workoutExercise: workoutExercise
                )
                context.insert(workoutSet)
            }
        }

        template.lastUsedAt = .now
        try? context.save()

        activeWorkout = workout
        elapsedSeconds = 0
        startElapsedTimer()
        startLiveActivity()
        backgroundAudio.startSilentAudio()
    }

    // MARK: - Start Empty Workout

    func startEmptyWorkout(context: ModelContext) {
        guard activeWorkout == nil else { return }
        self.modelContext = context

        let workout = Workout(name: "Workout")
        context.insert(workout)
        try? context.save()

        activeWorkout = workout
        elapsedSeconds = 0
        startElapsedTimer()
        startLiveActivity()
        backgroundAudio.startSilentAudio()
    }

    // MARK: - Complete Set

    func completeSet(_ workoutSet: WorkoutSet, context: ModelContext) {
        if workoutSet.isCompleted {
            workoutSet.isCompleted = false
            workoutSet.completedAt = nil
            try? context.save()

            if lastCompletedSetId == workoutSet.id {
                restTimer.stop()
                lastCompletedSetId = nil
                cancelBackgroundRestExpiry()
            }
            updateLiveActivity()
            cacheCurrentState()
            return
        }

        workoutSet.isCompleted = true
        workoutSet.completedAt = .now
        try? context.save()

        lastCompletedSetId = workoutSet.id
        let restDuration = workoutSet.workoutExercise?.exercise?.defaultRestSeconds ?? 120
        restTimer.start(duration: restDuration)
        updateLiveActivity()
        cacheCurrentState()
        scheduleBackgroundRestExpiry(duration: restDuration)
    }

    // MARK: - Delete Set

    func deleteSet(_ workoutSet: WorkoutSet, context: ModelContext) {
        let exercise = workoutSet.workoutExercise

        if lastCompletedSetId == workoutSet.id {
            restTimer.stop()
            lastCompletedSetId = nil
        }

        context.delete(workoutSet)

        if let exercise {
            for (i, set) in exercise.sortedSets.enumerated() {
                set.order = i
            }
        }
        try? context.save()
        updateLiveActivity()
        cacheCurrentState()
    }

    // MARK: - Reset

    func reset() {
        restTimer.stop()
        backgroundAudio.stopSilentAudio()
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
        lastCompletedSetId = nil
        hasInterruptedWorkout = false
    }

    // MARK: - Finish Workout

    func finishWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }

        workout.isInProgress = false
        workout.completedAt = .now
        workout.durationSeconds = Int(Date.now.timeIntervalSince(workout.startedAt))
        try? context.save()

        restTimer.stop()
        backgroundAudio.stopSilentAudio()
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
    }

    // MARK: - Discard Workout

    func discardWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }

        context.delete(workout)
        try? context.save()

        restTimer.stop()
        backgroundAudio.stopSilentAudio()
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
    }

    // MARK: - Live Activity Lifecycle

    private func startLiveActivity() {
        guard let workout = activeWorkout else { return }
        let state = liveActivityService.buildContentState(from: self)
        currentActivity = liveActivityService.startActivity(
            workoutName: workout.name,
            startedAt: workout.startedAt,
            initialState: state
        )
        cacheCurrentState()
    }

    func updateLiveActivity(alertConfiguration: AlertConfiguration? = nil) {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.updateActivity(activity, state: state, alertConfiguration: alertConfiguration)
    }

    func updateLiveActivity(with state: WorkoutActivityAttributes.ContentState, alertConfiguration: AlertConfiguration? = nil) {
        guard let activity = currentActivity else { return }
        liveActivityService.updateActivity(activity, state: state, alertConfiguration: alertConfiguration)
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.endActivity(activity, finalState: state)
        currentActivity = nil
        LiveActivityCache.clear()
    }

    func reconnectLiveActivity() {
        guard activeWorkout != nil, currentActivity == nil else { return }
        for activity in Activity<WorkoutActivityAttributes>.activities {
            currentActivity = activity
            updateLiveActivity()
            cacheCurrentState()
            return
        }
        // No existing activity found — start a new one
        startLiveActivity()
    }

    private func cacheCurrentState() {
        let state = liveActivityService.buildContentState(from: self)
        let setId = findCurrentSet()?.1.id
        let restDuration = findCurrentSet()?.0.exercise?.defaultRestSeconds ?? 120
        LiveActivityCache.cache(state, setId: setId, restDuration: restDuration)
    }

    // MARK: - Intent Handlers (called from LiveActivityIntents)

    func completeCurrentSetFromIntent() {
        guard var cachedState = LiveActivityCache.state,
              let setId = LiveActivityCache.setId,
              !cachedState.isWorkoutComplete else { return }

        let restDuration = LiveActivityCache.restDuration > 0 ? LiveActivityCache.restDuration : 120
        restTimer.start(duration: restDuration)

        cachedState.isRestTimerActive = true
        cachedState.restTimerEndDate = restTimer.endDate ?? Date.now.addingTimeInterval(Double(restDuration))
        cachedState.restTotalSeconds = restDuration

        LiveActivityCache.state = cachedState
        LiveActivityCache.recordCompletion(setId: setId)
        lastCompletedSetId = setId

        updateLiveActivity(with: cachedState)
        scheduleBackgroundRestExpiry(duration: restDuration)
    }

    func adjustWeightFromIntent(delta: Double) {
        if checkAndHandleExpiredTimer() { return }
        guard let state = LiveActivityCache.adjustWeight(delta: delta) else { return }
        updateLiveActivity(with: state)
    }

    func adjustRepsFromIntent(delta: Int) {
        if checkAndHandleExpiredTimer() { return }
        guard let state = LiveActivityCache.adjustReps(delta: delta) else { return }
        updateLiveActivity(with: state)
    }

    func skipRestTimerFromIntent() {
        if checkAndHandleExpiredTimer() { return }
        restTimer.stop()
        lastCompletedSetId = nil
        cancelBackgroundRestExpiry()
        applyPendingCompletionsInMemory()
        updateLiveActivity()
        cacheCurrentState()
    }

    /// Returns true if the timer had expired and was handled (caller should return early)
    @discardableResult
    func checkAndHandleExpiredTimer() -> Bool {
        guard restTimer.isRunning,
              let endDate = restTimer.endDate,
              endDate.timeIntervalSinceNow <= 0 else { return false }
        restTimer.stop()
        handleTimerExpired()
        return true
    }

    // MARK: - Timer Expiry Handler

    private func handleTimerExpired() {
        lastCompletedSetId = nil
        cancelBackgroundRestExpiry()

        // Apply any pending lock screen completions to in-memory SwiftData
        // so buildContentState finds the correct next set
        applyPendingCompletionsInMemory()

        // Play alert sound directly through our audio session — the
        // AlertConfiguration sound is suppressed by the active .playback session
        backgroundAudio.playAlertSound()

        let alert = AlertConfiguration(
            title: "Rest Complete",
            body: "Time for your next set!",
            sound: .default
        )
        updateLiveActivity(alertConfiguration: alert)
        cacheCurrentState()
    }

    /// Marks pending completion set IDs as complete in the in-memory model graph
    /// (no context.save — just so buildContentState traversal sees them).
    private func applyPendingCompletionsInMemory() {
        guard let workout = activeWorkout else { return }
        let pendingIds = LiveActivityCache.pendingCompletionIds
        guard !pendingIds.isEmpty else { return }

        for exercise in workout.sortedExercises {
            for set in exercise.sortedSets {
                if pendingIds.contains(set.id) && !set.isCompleted {
                    set.isCompleted = true
                    set.completedAt = .now
                }
            }
        }
    }

    // MARK: - Background Rest Timer

    private func scheduleBackgroundRestExpiry(duration: Int) {
        cancelBackgroundRestExpiry()

        backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                if self.restTimer.isRunning {
                    self.restTimer.stop()
                    self.handleTimerExpired()
                }
                self.endBackgroundTask()
            }
        }
        restExpiryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration) + 0.5, execute: workItem)
    }

    private func cancelBackgroundRestExpiry() {
        restExpiryWorkItem?.cancel()
        restExpiryWorkItem = nil
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }

    // MARK: - Foreground Resume

    func handleForegroundResume() {
        let wasTimerRunning = restTimer.isRunning
        restTimer.syncFromPersistedState()

        if wasTimerRunning && !restTimer.isRunning {
            lastCompletedSetId = nil
        }

        guard isWorkoutInProgress else { return }

        // Ensure audio is alive — restart if iOS reclaimed it while backgrounded
        if !backgroundAudio.isPlaying {
            backgroundAudio.startSilentAudio()
        }

        // Sync cached lock screen changes to SwiftData
        syncCacheToSwiftData()

        if currentActivity == nil {
            reconnectLiveActivity()
        } else {
            updateLiveActivity()
        }
    }

    private func syncCacheToSwiftData() {
        guard let context = modelContext,
              let pending = LiveActivityCache.consumePendingSync() else { return }

        // Apply completions from lock screen
        for completedId in pending.completedSetIds {
            let descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate<WorkoutSet> { $0.id == completedId }
            )
            if let set = try? context.fetch(descriptor).first, !set.isCompleted {
                set.isCompleted = true
                set.completedAt = .now
            }
        }

        // Apply weight/reps adjustments from lock screen
        if pending.isDirty, let cachedState = pending.currentState,
           let (_, currentSet) = findCurrentSet() {
            currentSet.weight = cachedState.weight
            currentSet.reps = cachedState.reps
            currentSet.seconds = cachedState.duration
            currentSet.distance = cachedState.distance
        }

        try? context.save()
        cacheCurrentState()
    }

    // MARK: - Elapsed Timer

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let workout = self.activeWorkout else { return }
                self.elapsedSeconds = Int(Date.now.timeIntervalSince(workout.startedAt))
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Set Progression

    func findCurrentSet() -> (WorkoutExercise, WorkoutSet)? {
        guard let workout = activeWorkout else { return nil }
        for exercise in workout.sortedExercises {
            for set in exercise.sortedSets {
                if !set.isCompleted {
                    return (exercise, set)
                }
            }
        }
        return nil
    }

    var hasCompletedSets: Bool {
        guard let workout = activeWorkout else { return false }
        return workout.exercises.flatMap(\.sets).contains { $0.isCompleted }
    }

    var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
