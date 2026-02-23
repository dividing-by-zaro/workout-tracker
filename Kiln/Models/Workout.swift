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

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var totalVolume: Double {
        exercises.flatMap { $0.sets }.reduce(0.0) { total, set in
            total + (set.weight ?? 0) * Double(set.reps ?? 0)
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
