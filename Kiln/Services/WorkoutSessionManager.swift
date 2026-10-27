import ActivityKit
import Foundation
import SwiftData
import SwiftUI
import UIKit

struct TemplateDiff {
    var moved: Int
    var added: Int
    var removed: Int

    var hasChanges: Bool {
        moved > 0 || added > 0 || removed > 0
    }

    var description: String {
        var parts: [String] = []
        if moved > 0 { parts.append("Moves \(moved) exercise\(moved == 1 ? "" : "s")") }
        if added > 0 { parts.append("Adds \(added) exercise\(added == 1 ? "" : "s")") }
        if removed > 0 { parts.append("Removes \(removed) exercise\(removed == 1 ? "" : "s")") }
        return parts.joined(separator: ". ") + "."
    }
}

private struct SetCompletionTransition {
    let setId: UUID
    let isLastSetInExercise: Bool
    let restDuration: Int
}

@MainActor
private final class WorkoutSessionPersistenceController {
    private(set) var modelContext: ModelContext?
    private var pendingSaveWorkItem: DispatchWorkItem?

    func bind(_ context: ModelContext) {
        modelContext = context
    }

    func saveNow(using context: ModelContext? = nil) {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        try? (context ?? modelContext)?.save()
    }

    func scheduleSave(after delay: TimeInterval = 0.8) {
        guard modelContext != nil else { return }

        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelScheduledSave() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
    }
}

@MainActor
@Observable
final class WorkoutSessionManager {
    static var shared: WorkoutSessionManager?

    var activeWorkout: Workout?
    var isWorkoutInProgress: Bool { activeWorkout != nil }
    var elapsedSeconds: Int = 0
    var lastCompletedSetId: UUID?

    let restTimer = RestTimerService()
    let liveActivityService = LiveActivityService()
    let notificationService = NotificationService()
    let timerBackend = TimerBackendService()
    var syncService: WorkoutSyncService?

    private var currentActivity: Activity<WorkoutActivityAttributes>?
    private var currentPushToken: String?
    private var deviceId: String { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
    private let persistenceController = WorkoutSessionPersistenceController()
    private var elapsedTimer: Timer?
    private var pendingLiveActivitySyncItem: DispatchWorkItem?

    var showResumedToast: Bool = false
    var celebrationData: CelebrationData?
    var shouldSwitchToWorkoutTab: Bool = false

    private var modelContext: ModelContext? {
        persistenceController.modelContext
    }

    init() {
        Self.shared = self
        restTimer.onTimerExpired = { [weak self] playSound in
            self?.handleTimerExpired(playSound: playSound)
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.flushLiveActivityOnResignActive()
            }
        }
    }

    private func flushLiveActivityOnResignActive() {
        persistenceController.saveNow()
        guard activeWorkout != nil else { return }
        guard currentActivity != nil else { return }
        cancelPendingLiveActivitySync()
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
    }

    func setModelContext(_ context: ModelContext) {
        persistenceController.bind(context)
    }

    // MARK: - Crash Recovery

    func checkForInterruptedWorkout(context: ModelContext) {
        persistenceController.bind(context)
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isInProgress == true }
        )
        guard let workouts = try? context.fetch(descriptor),
              let interrupted = workouts.first else {
            return
        }
        activeWorkout = interrupted
        startElapsedTimer()
        syncCacheToSwiftData()
        restTimer.syncFromPersistedState()
        reconnectLiveActivity()
        showResumedToast = true
    }

    // MARK: - Start Workout from Template

    func startWorkout(from template: WorkoutTemplate, context: ModelContext) {
        guard activeWorkout == nil else { return }
        persistenceController.bind(context)

        let workout = Workout(name: template.name, templateId: template.id)
        context.insert(workout)
        let completedWorkouts = WorkoutHistoryService.fetchCompletedWorkouts(context: context) ?? []

        // Carry forward the note from the most recent run of this template so the user
        // sees what they wrote for their future self.
        if let previous = completedWorkouts.first(where: { $0.templateId == template.id }),
           let previousNotes = previous.notes, !previousNotes.isEmpty {
            workout.notes = previousNotes
        }

        for (index, templateExercise) in template.sortedExercises.enumerated() {
            guard let exercise = templateExercise.exercise else { continue }

            let workoutExercise = WorkoutExercise(order: index, exercise: exercise, workout: workout)
            context.insert(workoutExercise)

            let preFillData = PreFillService.preFillSets(
                for: exercise,
                setCount: templateExercise.defaultSets,
                in: completedWorkouts
            )

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

        persistenceController.saveNow(using: context)

        activeWorkout = workout
        elapsedSeconds = 0
        startElapsedTimer()
        startLiveActivity()
    }

    // MARK: - Start Empty Workout

    func startEmptyWorkout(context: ModelContext) {
        guard activeWorkout == nil else { return }
        persistenceController.bind(context)

        let workout = Workout(name: "Workout")
        context.insert(workout)
        persistenceController.saveNow(using: context)

        activeWorkout = workout
        elapsedSeconds = 0
        startElapsedTimer()
        startLiveActivity()
    }

    func handleSetValueChange(for workoutSet: WorkoutSet) {
        persistenceController.scheduleSave()

        guard findCurrentSet()?.1.id == workoutSet.id else { return }
        scheduleLiveActivitySync()
    }

    private func scheduleLiveActivitySync(after delay: TimeInterval = 0.25) {
        pendingLiveActivitySyncItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.flushPendingLiveActivitySync()
        }
        pendingLiveActivitySyncItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelPendingLiveActivitySync() {
        pendingLiveActivitySyncItem?.cancel()
        pendingLiveActivitySyncItem = nil
    }

    private func flushPendingLiveActivitySync() {
        pendingLiveActivitySyncItem?.cancel()
        pendingLiveActivitySyncItem = nil
        guard activeWorkout != nil, currentActivity != nil else { return }
        syncLiveActivityState()
    }

    private func stopRestTimer(cancelBackend: Bool = false) {
        restTimer.stop()
        lastCompletedSetId = nil
        notificationService.cancelRestTimer()
        if cancelBackend {
            sendTimerCancelToBackend()
        }
    }

    private func startRestTimer(duration: Int) {
        notificationService.cancelRestTimer()
        restTimer.start(duration: duration)
        notificationService.scheduleRestTimer(duration: duration)
    }

    private func buildCompletionTransition(for workoutSet: WorkoutSet) -> SetCompletionTransition {
        let isLastSetInExercise = workoutSet.workoutExercise.map { exercise in
            exercise.sortedSets.allSatisfy { $0.isCompleted }
        } ?? false

        return SetCompletionTransition(
            setId: workoutSet.id,
            isLastSetInExercise: isLastSetInExercise,
            restDuration: workoutSet.workoutExercise?.exercise?.defaultRestSeconds ?? 120
        )
    }

    /// Single canonical set-completion transition. `lockScreenNextState` is set only on
    /// the Live Activity intent path, which must never touch SwiftData (doing so forces
    /// FaceID on the lock screen) — it advances through the precomputed cache queue instead.
    private func applySetCompletion(
        _ transition: SetCompletionTransition,
        lockScreenNextState: WorkoutActivityAttributes.ContentState? = nil
    ) {
        lastCompletedSetId = transition.setId

        if !transition.isLastSetInExercise {
            startRestTimer(duration: transition.restDuration)
        }

        let state: WorkoutActivityAttributes.ContentState
        if var nextState = lockScreenNextState {
            LiveActivityCache.recordCompletion(setId: transition.setId)
            liveActivityService.applyRestTimer(restTimer, to: &nextState)
            LiveActivityCache.advance(to: nextState)
            state = nextState
        } else {
            state = liveActivityService.buildContentState(from: self)
            cacheCurrentState(using: state)
        }
        updateLiveActivity(with: state)

        if !transition.isLastSetInExercise {
            sendTimerScheduleToBackend(duration: transition.restDuration, nextState: state)
        }
    }

    // MARK: - Complete Set

    func completeSet(_ workoutSet: WorkoutSet, context: ModelContext) {
        cancelPendingLiveActivitySync()

        if workoutSet.isCompleted {
            workoutSet.isCompleted = false
            workoutSet.completedAt = nil
            persistenceController.saveNow(using: context)

            if lastCompletedSetId == workoutSet.id {
                stopRestTimer(cancelBackend: true)
            }
            let state = liveActivityService.buildContentState(from: self)
            updateLiveActivity(with: state)
            cacheCurrentState(using: state)
            return
        }

        workoutSet.isCompleted = true
        workoutSet.completedAt = .now
        persistenceController.saveNow(using: context)

        applySetCompletion(buildCompletionTransition(for: workoutSet))
    }

    // MARK: - Delete Set

    func deleteSet(_ workoutSet: WorkoutSet, context: ModelContext) {
        cancelPendingLiveActivitySync()

        let exercise = workoutSet.workoutExercise

        if lastCompletedSetId == workoutSet.id {
            stopRestTimer(cancelBackend: true)
        }

        context.delete(workoutSet)

        if let exercise {
            for (i, set) in exercise.sortedSets.enumerated() {
                set.order = i
            }
        }
        persistenceController.saveNow(using: context)
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
    }

    // MARK: - Remove Exercise

    func removeExercise(_ exercise: WorkoutExercise, context: ModelContext) {
        cancelPendingLiveActivitySync()

        // If the rest timer is running for a set in this exercise, stop it
        if let completedId = lastCompletedSetId,
           exercise.sets.contains(where: { $0.id == completedId }) {
            stopRestTimer(cancelBackend: true)
        }

        context.delete(exercise)

        // Re-normalize order on remaining exercises
        if let workout = activeWorkout {
            for (i, ex) in workout.sortedExercises.enumerated() {
                ex.order = i
            }
        }

        persistenceController.saveNow(using: context)
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
    }

    // MARK: - Reorder Exercises

    func reorderExercises(_ exercises: [WorkoutExercise], context: ModelContext) {
        cancelPendingLiveActivitySync()

        for (i, exercise) in exercises.enumerated() {
            exercise.order = i
        }
        persistenceController.saveNow(using: context)
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
        rescheduleBackendTimerIfNeeded()
    }

    // MARK: - Sync Live Activity State

    func syncLiveActivityState() {
        pendingLiveActivitySyncItem?.cancel()
        pendingLiveActivitySyncItem = nil
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
        rescheduleBackendTimerIfNeeded()
    }

    /// Refreshes active-workout state after a library-level exercise rename,
    /// merge, or deletion. A direct deletion can remove the set that owns the
    /// current rest timer, so clear that timer before rebuilding Live Activity.
    func handleExerciseLibraryMutation(context: ModelContext) {
        persistenceController.bind(context)
        cancelPendingLiveActivitySync()

        if let completedId = lastCompletedSetId,
           activeWorkout?.exercises.flatMap(\.sets).contains(where: { $0.id == completedId }) != true {
            stopRestTimer(cancelBackend: true)
        }

        persistenceController.saveNow(using: context)
        guard activeWorkout != nil else { return }
        let state = liveActivityService.buildContentState(from: self)
        updateLiveActivity(with: state)
        cacheCurrentState(using: state)
        rescheduleBackendTimerIfNeeded()
    }

    // MARK: - Reset

    func reset() {
        persistenceController.cancelScheduledSave()
        cancelPendingLiveActivitySync()
        stopRestTimer(cancelBackend: false)
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
        lastCompletedSetId = nil
    }

    // MARK: - Celebration Data

    private func computeCelebrationData(for workout: Workout, context: ModelContext) {
        let completedSets = workout.exercises.flatMap(\.sets).filter(\.isCompleted)

        let totalSets = completedSets.count
        let totalReps = completedSets.compactMap(\.reps).reduce(0, +)
        let totalDistance = completedSets.compactMap(\.distance).reduce(0, +)

        var hasWeight = false
        var hasReps = false
        var hasDistance = false
        for workoutExercise in workout.exercises {
            guard let equipType = workoutExercise.exercise?.resolvedEquipmentType else { continue }
            if equipType.tracksWeight { hasWeight = true }
            if equipType.tracksReps { hasReps = true }
            if equipType.tracksDistance { hasDistance = true }
        }

        let countDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isInProgress == false }
        )
        let workoutCount = (try? context.fetchCount(countDescriptor)) ?? 1

        celebrationData = CelebrationData(
            workoutName: workout.name,
            duration: workout.formattedDuration,
            totalVolume: workout.totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            totalDistance: totalDistance,
            workoutCount: workoutCount,
            hasWeightStats: hasWeight,
            hasRepsStats: hasReps,
            hasDistanceStats: hasDistance,
            personalRecords: []
        )
    }

    // MARK: - Finish Workout

    func finishWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }

        persistenceController.cancelScheduledSave()
        cancelPendingLiveActivitySync()
        workout.isInProgress = false
        workout.completedAt = .now
        workout.durationSeconds = Int(Date.now.timeIntervalSince(workout.startedAt))

        if let templateId = workout.templateId {
            let descriptor = FetchDescriptor<WorkoutTemplate>(
                predicate: #Predicate<WorkoutTemplate> { $0.id == templateId }
            )
            if let template = try? context.fetch(descriptor).first {
                template.lastUsedAt = .now
            }
        }

        persistenceController.saveNow(using: context)

        computeCelebrationData(for: workout, context: context)

        // Fire-and-forget sync to backend
        if let syncService {
            let workoutToSync = workout
            Task { await syncService.uploadWorkout(workoutToSync) }
        }

        stopRestTimer(cancelBackend: true)
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
    }

    // MARK: - Discard Workout

    func discardWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }

        persistenceController.cancelScheduledSave()
        cancelPendingLiveActivitySync()
        context.delete(workout)
        persistenceController.saveNow(using: context)

        stopRestTimer(cancelBackend: true)
        stopElapsedTimer()
        endLiveActivity()
        activeWorkout = nil
        elapsedSeconds = 0
    }

    // MARK: - Template Diff & Update

    func computeTemplateDiff(context: ModelContext) -> TemplateDiff? {
        guard let workout = activeWorkout,
              let templateId = workout.templateId else { return nil }

        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate<WorkoutTemplate> { $0.id == templateId }
        )
        guard let template = try? context.fetch(descriptor).first else { return nil }

        let templateExerciseIds = template.sortedExercises.compactMap { $0.exercise?.id }
        let workoutExerciseIds = workout.sortedExercises.compactMap { $0.exercise?.id }

        let templateSet = Set(templateExerciseIds)
        let workoutSet = Set(workoutExerciseIds)

        let added = workoutSet.subtracting(templateSet).count
        let removed = templateSet.subtracting(workoutSet).count

        // Count moved: among common exercises, how many changed relative position
        let commonInTemplate = templateExerciseIds.filter { workoutSet.contains($0) }
        let commonInWorkout = workoutExerciseIds.filter { templateSet.contains($0) }
        var moved = 0
        for (i, id) in commonInTemplate.enumerated() {
            if i < commonInWorkout.count && commonInWorkout[i] != id {
                moved += 1
            }
        }

        return TemplateDiff(moved: moved, added: added, removed: removed)
    }

    func finishAndUpdateTemplate(context: ModelContext) {
        guard let workout = activeWorkout,
              let templateId = workout.templateId else { return }

        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate<WorkoutTemplate> { $0.id == templateId }
        )
        guard let template = try? context.fetch(descriptor).first else { return }

        // Delete existing template exercises
        for existing in template.exercises {
            context.delete(existing)
        }

        // Create new template exercises from workout
        for workoutExercise in workout.sortedExercises {
            let templateExercise = TemplateExercise(
                order: workoutExercise.order,
                defaultSets: workoutExercise.sets.count,
                exercise: workoutExercise.exercise,
                template: template
            )
            context.insert(templateExercise)
        }

        persistenceController.saveNow(using: context)

        finishWorkout(context: context)
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
        if let activity = currentActivity {
            observePushToken(for: activity)
        }
        cacheCurrentState()
    }

    func updateLiveActivity() {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.updateActivity(activity, state: state)
    }

    func updateLiveActivity(with state: WorkoutActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }
        liveActivityService.updateActivity(activity, state: state)
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let state = liveActivityService.buildContentState(from: self)
        liveActivityService.endActivity(activity, finalState: state)
        currentActivity = nil
        LiveActivityCache.clear()
    }

    func reconnectLiveActivity() {
        guard activeWorkout != nil else { return }
        if currentActivity != nil || attachToExistingActivity() {
            updateLiveActivity()
            cacheCurrentState()
            return
        }
        // No existing activity found — start a new one
        startLiveActivity()
    }

    /// Re-binds to a running Live Activity after the process was relaunched (e.g. by a
    /// lock screen intent after iOS killed the app). ActivityKit + cache only — no SwiftData.
    @discardableResult
    private func attachToExistingActivity() -> Bool {
        if currentActivity != nil { return true }
        guard let activity = Activity<WorkoutActivityAttributes>.activities.first else { return false }
        currentActivity = activity
        // Restore persisted push token immediately; also start observing
        // in case iOS issues a new token for this activity.
        if currentPushToken == nil, let cached = LiveActivityCache.pushToken {
            currentPushToken = cached
        }
        observePushToken(for: activity)
        return true
    }

    private func observePushToken(for activity: Activity<WorkoutActivityAttributes>) {
        liveActivityService.observePushToken(activity: activity) { [weak self] token in
            Task { @MainActor in
                self?.currentPushToken = token
                LiveActivityCache.pushToken = token
            }
        }
    }

    /// App-side only (reads SwiftData). Lock screen intents use `LiveActivityCache.advance`.
    private func cacheCurrentState(using state: WorkoutActivityAttributes.ContentState? = nil) {
        let resolvedState = state ?? liveActivityService.buildContentState(from: self)
        LiveActivityCache.cache(resolvedState, queue: liveActivityService.buildQueue(from: self))
    }

    // MARK: - Intent Handlers (called from LiveActivityIntents)
    //
    // These run from the lock screen, possibly in a freshly relaunched process with no
    // active workout loaded. They must only touch LiveActivityCache, ActivityKit, the rest
    // timer and notifications — any SwiftData access forces FaceID.

    func completeCurrentSetFromIntent() {
        prepareForIntent()
        let queue = LiveActivityCache.queue
        guard let state = LiveActivityCache.state,
              !state.isWorkoutComplete,
              let current = queue.first,
              current.setId == LiveActivityCache.setId else { return }

        let next = queue.dropFirst().first
        let isLastSetInExercise = next?.workoutExerciseId != current.workoutExerciseId
        var nextState = next?.state ?? liveActivityService.completedContentState()
        if !isLastSetInExercise {
            // Same exercise: carry summaries forward so lock screen adjustments stay visible.
            var summaries = state.setSummaries
            let completedIndex = state.setNumber - 1
            if summaries.indices.contains(completedIndex) {
                summaries[completedIndex].isCompleted = true
            }
            nextState.setSummaries = summaries
        }

        applySetCompletion(
            SetCompletionTransition(
                setId: current.setId,
                isLastSetInExercise: isLastSetInExercise,
                restDuration: current.restDuration
            ),
            lockScreenNextState: nextState
        )
    }

    func adjustWeightFromIntent(delta: Double) {
        prepareForIntent()
        guard let state = LiveActivityCache.adjustWeight(delta: delta) else { return }
        updateLiveActivity(with: state)
    }

    func adjustRepsFromIntent(delta: Int) {
        prepareForIntent()
        guard let state = LiveActivityCache.adjustReps(delta: delta) else { return }
        updateLiveActivity(with: state)
    }

    func skipRestTimerFromIntent() {
        prepareForIntent()
        stopRestTimer(cancelBackend: true)
        LiveActivityCache.clearRest()
        if let state = LiveActivityCache.state {
            updateLiveActivity(with: state)
        }
    }

    func skipRestTimer() {
        stopRestTimer(cancelBackend: true)
        syncLiveActivityState()
    }

    /// Restores process state an intent depends on, and silently clears a rest period
    /// that already ended (the backend push has likely moved the Live Activity to the
    /// next set), so the tap applies to the set instead of reviving the timer view.
    private func prepareForIntent() {
        attachToExistingActivity()
        if !restTimer.isRunning {
            restTimer.syncFromPersistedState()
        }
        if restTimer.isRunning, let endDate = restTimer.endDate, endDate.timeIntervalSinceNow <= 0 {
            restTimer.stop()
            handleTimerExpired(playSound: false)
        }
        if let state = LiveActivityCache.state, state.isRestTimerActive, state.restTimerEndDate <= .now {
            LiveActivityCache.clearRest()
        }
    }

    // MARK: - Timer Expiry Handler

    /// The rest notification is the single source of the alert sound, so the Live
    /// Activity update carries no AlertConfiguration. Outside the foreground this is
    /// cache-only, so it is safe from lock screen intents and background expiry.
    private func handleTimerExpired(playSound: Bool = true) {
        lastCompletedSetId = nil
        if !playSound {
            notificationService.cancelRestTimer()
        }
        if UIApplication.shared.applicationState == .active, activeWorkout != nil {
            syncLiveActivityState()
            return
        }
        LiveActivityCache.clearRest()
        if let state = LiveActivityCache.state {
            updateLiveActivity(with: state)
        }
    }

    // MARK: - Foreground Resume

    func handleForegroundResume() {
        cancelPendingLiveActivitySync()

        // Sync cached lock screen changes to SwiftData before anything rebuilds state
        if isWorkoutInProgress {
            syncCacheToSwiftData()
        }

        let wasTimerRunning = restTimer.isRunning
        restTimer.syncFromPersistedState()

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

        // Apply weight/reps adjustments to each set that was adjusted on the lock screen
        for (adjustedSetId, values) in pending.adjustedValues {
            let descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate<WorkoutSet> { $0.id == adjustedSetId }
            )
            if let adjustedSet = try? context.fetch(descriptor).first {
                adjustedSet.weight = values.weight
                adjustedSet.reps = values.reps
                adjustedSet.seconds = values.duration
                adjustedSet.distance = values.distance
            }
        }

        persistenceController.saveNow(using: context)
        cacheCurrentState()
    }

    // MARK: - Timer Backend

    /// `nextState` is the set shown after rest; the backend pushes it with rest cleared.
    private func sendTimerScheduleToBackend(duration: Int, nextState: WorkoutActivityAttributes.ContentState) {
        guard let pushToken = currentPushToken else { return }
        var nextState = nextState
        nextState.isRestTimerActive = false
        nextState.restTimerEndDate = .distantPast
        nextState.restTotalSeconds = 0

        guard let encoded = try? JSONEncoder().encode(nextState),
              let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else { return }

        timerBackend.scheduleTimer(
            pushToken: pushToken,
            duration: duration,
            contentState: dict,
            deviceId: deviceId
        )
    }

    private func sendTimerCancelToBackend() {
        timerBackend.cancelTimer(deviceId: deviceId)
    }

    /// Re-schedules the backend timer with updated content state when exercises
    /// are modified (swap/add/reorder) while a rest timer is actively running.
    /// Without this, the backend push would deliver stale exercise data.
    private func rescheduleBackendTimerIfNeeded() {
        guard restTimer.isRunning,
              let endDate = restTimer.endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow)
        guard remaining > 0 else { return }
        sendTimerScheduleToBackend(duration: remaining, nextState: liveActivityService.buildContentState(from: self))
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
