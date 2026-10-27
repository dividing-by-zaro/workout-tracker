import ActivityKit
import Foundation
import UIKit

@MainActor
final class LiveActivityService {

    func startActivity(
        workoutName: String,
        startedAt: Date,
        initialState: WorkoutActivityAttributes.ContentState
    ) -> Activity<WorkoutActivityAttributes>? {
        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            workoutStartedAt: startedAt
        )
        let content = ActivityContent(state: initialState, staleDate: nil)
        // Try with push token first; fall back to no push if entitlement isn't provisioned
        if let activity = try? Activity<WorkoutActivityAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: .token
        ) {
            return activity
        }
        return try? Activity<WorkoutActivityAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    func updateActivity(
        _ activity: Activity<WorkoutActivityAttributes>,
        state: WorkoutActivityAttributes.ContentState
    ) {
        let content = ActivityContent(state: state, staleDate: nil)
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "live-activity-update") {
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
        }
        Task.detached(priority: .userInitiated) {
            await activity.update(content)
            await MainActor.run {
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
            }
        }
    }

    func endActivity(
        _ activity: Activity<WorkoutActivityAttributes>,
        finalState: WorkoutActivityAttributes.ContentState
    ) {
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }

    func buildContentState(from sessionManager: WorkoutSessionManager) -> WorkoutActivityAttributes.ContentState {
        guard let (exercise, set) = sessionManager.findCurrentSet() else {
            return completedContentState()
        }
        var state = contentState(for: set, in: exercise)
        applyRestTimer(sessionManager.restTimer, to: &state)
        return state
    }

    /// Every incomplete set in progression order (current set first), so lock screen
    /// intents can advance the Live Activity from the cache without touching SwiftData.
    func buildQueue(from sessionManager: WorkoutSessionManager) -> [LiveActivityCache.QueuedSet] {
        guard let workout = sessionManager.activeWorkout else { return [] }
        var queue: [LiveActivityCache.QueuedSet] = []
        for exercise in workout.sortedExercises {
            let restDuration = exercise.exercise?.defaultRestSeconds ?? 120
            for set in exercise.sortedSets where !set.isCompleted {
                queue.append(LiveActivityCache.QueuedSet(
                    setId: set.id,
                    workoutExerciseId: exercise.id,
                    restDuration: restDuration,
                    state: contentState(for: set, in: exercise)
                ))
            }
        }
        return queue
    }

    func applyRestTimer(_ restTimer: RestTimerService, to state: inout WorkoutActivityAttributes.ContentState) {
        state.isRestTimerActive = restTimer.isRunning
        state.restTimerEndDate = restTimer.endDate ?? .distantPast
        state.restTotalSeconds = restTimer.totalSeconds
    }

    /// State for `set` as if every set before it in the exercise is done.
    private func contentState(for set: WorkoutSet, in exercise: WorkoutExercise) -> WorkoutActivityAttributes.ContentState {
        let equipmentType = exercise.exercise?.resolvedEquipmentType ?? .barbell
        let category = equipmentType.equipmentCategory
        let sortedSets = exercise.sortedSets
        let setIndex = sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0

        let summaries = sortedSets.enumerated().map { index, s in
            SetSummary(
                label: formatSetSummaryLabel(for: s, category: category),
                isCompleted: s.isCompleted || index < setIndex
            )
        }

        return WorkoutActivityAttributes.ContentState(
            exerciseName: exercise.exercise?.name ?? "Exercise",
            setNumber: setIndex + 1,
            totalSetsInExercise: sortedSets.count,
            setSummaries: summaries,
            weight: set.weight,
            reps: set.reps,
            duration: set.seconds,
            distance: set.distance,
            equipmentCategory: category,
            isRestTimerActive: false,
            restTimerEndDate: .distantPast,
            restTotalSeconds: 0,
            isWorkoutComplete: false
        )
    }

    func completedContentState() -> WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            exerciseName: "",
            setNumber: 0,
            totalSetsInExercise: 0,
            setSummaries: [],
            weight: nil,
            reps: nil,
            duration: nil,
            distance: nil,
            equipmentCategory: "weightReps",
            isRestTimerActive: false,
            restTimerEndDate: .distantPast,
            restTotalSeconds: 0,
            isWorkoutComplete: true
        )
    }

    func observePushToken(activity: Activity<WorkoutActivityAttributes>, onToken: @escaping (String) -> Void) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                onToken(token)
            }
        }
    }

    func formatSetSummaryLabel(for set: WorkoutSet, category: String) -> String {
        SetFormatter.summaryLabel(
            equipmentCategory: category,
            weight: set.weight,
            reps: set.reps,
            seconds: set.seconds,
            distance: set.distance
        )
    }
}
