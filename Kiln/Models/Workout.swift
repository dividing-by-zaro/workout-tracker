import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var name: String
    var startedAt: Date
    var completedAt: Date?
    var durationSeconds: Int?
    var isInProgress: Bool
    var templateId: UUID?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var totalVolume: Double {
        exercises.reduce(0.0) { workoutTotal, workoutExercise in
            let equipmentType = workoutExercise.exercise?.resolvedEquipmentType ?? .machineOther
            let exerciseTotal = workoutExercise.sets.filter(\.isCompleted).reduce(0.0) { setTotal, set in
                setTotal + equipmentType.trainingVolume(weight: set.weight, reps: set.reps)
            }
            return workoutTotal + exerciseTotal
        }
    }

    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "0m" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    init(
        id: UUID = UUID(),
        name: String = "Workout",
        startedAt: Date = .now,
        completedAt: Date? = nil,
        durationSeconds: Int? = nil,
        isInProgress: Bool = true,
        templateId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.isInProgress = isInProgress
        self.templateId = templateId
    }
}
