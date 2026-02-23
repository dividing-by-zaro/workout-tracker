import Foundation
import SwiftData
import SwiftUI

@Observable
final class WorkoutSessionManager {
    var activeWorkout: Workout?
    var isWorkoutInProgress: Bool { activeWorkout != nil }
    var elapsedSeconds: Int = 0
    var lastCompletedSetId: UUID?

    let restTimer = RestTimerService()

    private var modelContext: ModelContext?
    private var elapsedTimer: Timer?
    private var hasRequestedNotificationPermission = false

    var hasInterruptedWorkout: Bool = false

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Crash Recovery (T030)

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
    }

    func discardInterruptedWorkout(context: ModelContext) {
        hasInterruptedWorkout = false
        discardWorkout(context: context)
    }

    // MARK: - Start Workout from Template

    func startWorkout(from template: WorkoutTemplate, context: ModelContext) {
        guard activeWorkout == nil else { return }
        self.modelContext = context

        if !hasRequestedNotificationPermission {
            RestTimerService.requestPermission()
            hasRequestedNotificationPermission = true
        }

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
    }

    // MARK: - Start Empty Workout

    func startEmptyWorkout(context: ModelContext) {
        guard activeWorkout == nil else { return }
        self.modelContext = context

        if !hasRequestedNotificationPermission {
            RestTimerService.requestPermission()
            hasRequestedNotificationPermission = true
        }

        let workout = Workout(name: "Workout")
        context.insert(workout)
        try? context.save()

        activeWorkout = workout
        elapsedSeconds = 0
        startElapsedTimer()
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
            }
            return
        }

        workoutSet.isCompleted = true
        workoutSet.completedAt = .now
        try? context.save()

        lastCompletedSetId = workoutSet.id
        let restDuration = workoutSet.workoutExercise?.exercise?.defaultRestSeconds ?? 120
        restTimer.start(duration: restDuration)
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
    }

    // MARK: - Reset

    func reset() {
        restTimer.stop()
        stopElapsedTimer()
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
        activeWorkout = nil
        elapsedSeconds = 0
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
