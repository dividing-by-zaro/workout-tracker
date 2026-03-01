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
            return
        }

        workoutSet.isCompleted = true
        workoutSet.completedAt = .now
        try? context.save()

        lastCompletedSetId = workoutSet.id
        let restDuration = workoutSet.workoutExercise?.exercise?.defaultRestSeconds ?? 120
        restTimer.start(duration: restDuration)
        updateLiveActivity()
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
    }

    // MARK: - Reset

    func reset() {
        restTimer.stop()
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
    }

    func updateLiveActivity(alertConfiguration: AlertConfiguration? = nil) {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.updateActivity(activity, state: state, alertConfiguration: alertConfiguration)
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.endActivity(activity, finalState: state)
        currentActivity = nil
    }

    func reconnectLiveActivity() {
        guard activeWorkout != nil, currentActivity == nil else { return }
        for activity in Activity<WorkoutActivityAttributes>.activities {
            currentActivity = activity
            updateLiveActivity()
            return
        }
        // No existing activity found — start a new one
        startLiveActivity()
    }

    // MARK: - Intent Handlers (called from LiveActivityIntents)

    func completeCurrentSetFromIntent() {
        guard let context = modelContext,
              let (exercise, set) = findCurrentSet() else { return }

        set.isCompleted = true
        set.completedAt = .now
        try? context.save()

        lastCompletedSetId = set.id
        let restDuration = exercise.exercise?.defaultRestSeconds ?? 120
        restTimer.start(duration: restDuration)
        updateLiveActivity()
        scheduleBackgroundRestExpiry(duration: restDuration)
    }

    func adjustWeightFromIntent(delta: Double) {
        if checkAndHandleExpiredTimer() { return }
        guard let context = modelContext,
              let (exercise, set) = findCurrentSet() else { return }

        let equipmentType = exercise.exercise?.resolvedEquipmentType ?? .barbell
        switch equipmentType.equipmentCategory {
        case "weightReps", "weightDistance":
            set.weight = max(0, (set.weight ?? 0) + delta)
        case "duration":
            set.seconds = max(0, (set.seconds ?? 0) + delta)
        case "distance":
            set.distance = max(0, (set.distance ?? 0) + delta)
        default:
            return
        }
        try? context.save()
        updateLiveActivity()
    }

    func adjustRepsFromIntent(delta: Int) {
        if checkAndHandleExpiredTimer() { return }
        guard let context = modelContext,
              let (_, set) = findCurrentSet() else { return }

        set.reps = max(0, (set.reps ?? 0) + delta)
        try? context.save()
        updateLiveActivity()
    }

    func skipRestTimerFromIntent() {
        if checkAndHandleExpiredTimer() { return }
        restTimer.stop()
        lastCompletedSetId = nil
        cancelBackgroundRestExpiry()
        updateLiveActivity()
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
        let alert = AlertConfiguration(
            title: "Rest Complete",
            body: "Time for your next set!",
            sound: .default
        )
        updateLiveActivity(alertConfiguration: alert)
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

        // Timer expired while backgrounded and background task didn't fire
        if wasTimerRunning && !restTimer.isRunning {
            lastCompletedSetId = nil
        }

        guard isWorkoutInProgress else { return }

        if currentActivity == nil {
            reconnectLiveActivity()
        } else {
            updateLiveActivity()
        }
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
