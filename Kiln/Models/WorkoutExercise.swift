import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var id: UUID
    var order: Int
    var exercise: Exercise?
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet] = []

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.order < $1.order }
    }

    init(
        id: UUID = UUID(),
        order: Int = 0,
        exercise: Exercise? = nil,
        workout: Workout? = nil
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.workout = workout
    }
}
