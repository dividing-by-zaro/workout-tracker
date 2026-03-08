import ActivityKit
import Foundation

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
        return try? Activity<WorkoutActivityAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: .token
        )
    }

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
        if let (exercise, set) = sessionManager.findCurrentSet() {
            let equipmentType = exercise.exercise?.resolvedEquipmentType ?? .barbell
            let category = equipmentType.equipmentCategory
            let previousLabel = formatPreviousSetLabel(for: set, equipmentType: equipmentType)

            let exerciseIndex = sessionManager.activeWorkout?.sortedExercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
            let totalExercises = sessionManager.activeWorkout?.sortedExercises.count ?? 0
            let setIndex = exercise.sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0

            return WorkoutActivityAttributes.ContentState(
                exerciseName: exercise.exercise?.name ?? "Exercise",
                setNumber: setIndex + 1,
                totalSetsInExercise: exercise.sortedSets.count,
                previousSetLabel: previousLabel,
                weight: set.weight,
                reps: set.reps,
                duration: set.seconds,
                distance: set.distance,
                equipmentCategory: category,
                isRestTimerActive: sessionManager.restTimer.isRunning,
                restTimerEndDate: sessionManager.restTimer.endDate ?? .distantPast,
                restTotalSeconds: sessionManager.restTimer.totalSeconds,
                isWorkoutComplete: false,
                exerciseIndex: exerciseIndex + 1,
                totalExercises: totalExercises
            )
        }

        // All sets complete
        return WorkoutActivityAttributes.ContentState(
            exerciseName: "",
            setNumber: 0,
            totalSetsInExercise: 0,
            previousSetLabel: "",
            weight: nil,
            reps: nil,
            duration: nil,
            distance: nil,
            equipmentCategory: "weightReps",
            isRestTimerActive: false,
            restTimerEndDate: .distantPast,
            restTotalSeconds: 0,
            isWorkoutComplete: true,
            exerciseIndex: 0,
            totalExercises: sessionManager.activeWorkout?.sortedExercises.count ?? 0
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

    private func formatPreviousSetLabel(for set: WorkoutSet, equipmentType: EquipmentType) -> String {
        // The pre-fill data is already stored on the set from PreFillService at workout start.
        // We format based on equipment category, matching the in-app PREVIOUS column.
        switch equipmentType.equipmentCategory {
        case "weightReps":
            if let w = set.weight, let r = set.reps {
                return "\(formatWeight(w)) lbs x \(r)"
            }
        case "repsOnly":
            if let r = set.reps {
                return "x \(r)"
            }
        case "duration":
            if let s = set.seconds {
                return "\(Int(s))s"
            }
        case "distance":
            if let d = set.distance {
                return "\(formatDistance(d)) mi"
            }
        case "weightDistance":
            if let w = set.weight, let d = set.distance {
                return "\(formatWeight(w)) lbs • \(formatDistance(d)) mi"
            }
        default:
            break
        }
        return "—"
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func formatDistance(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
