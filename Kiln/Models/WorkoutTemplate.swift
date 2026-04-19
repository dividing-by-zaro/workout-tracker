import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise] = []

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    static func averageDuration(for templateName: String, from workouts: [Workout]) -> String? {
        WorkoutHistoryService.templateSummary(for: templateName, in: workouts).averageDuration
    }

    static func workoutCount(for templateName: String, from workouts: [Workout]) -> Int {
        WorkoutHistoryService.templateSummary(for: templateName, in: workouts).workoutCount
    }
}
