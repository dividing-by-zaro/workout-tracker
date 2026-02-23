import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var distance: Double?
    var seconds: Double?
    var rpe: Double?
    var isCompleted: Bool
    var completedAt: Date?
    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        weight: Double? = nil,
        reps: Int? = nil,
        distance: Double? = nil,
        seconds: Double? = nil,
        rpe: Double? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        workoutExercise: WorkoutExercise? = nil
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.distance = distance
        self.seconds = seconds
        self.rpe = rpe
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.workoutExercise = workoutExercise
    }
}
