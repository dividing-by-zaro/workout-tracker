import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    let workoutName: String
    let workoutStartedAt: Date

    struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setNumber: Int
        var totalSetsInExercise: Int
        var previousSetLabel: String
        var weight: Double?
        var reps: Int?
        var duration: Double?
        var distance: Double?
        var equipmentCategory: String
        var isRestTimerActive: Bool
        var restTimerEndDate: Date
        var restTotalSeconds: Int
        var isWorkoutComplete: Bool
        var exerciseIndex: Int
        var totalExercises: Int
    }
}
