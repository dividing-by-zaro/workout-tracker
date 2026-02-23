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
        let durations = workouts
            .filter { $0.name == templateName && !$0.isInProgress && $0.durationSeconds != nil }
            .compactMap { $0.durationSeconds }
            .map { Double($0) }

        guard !durations.isEmpty else { return nil }

        let sorted = durations.sorted()
        let count = sorted.count

        if count < 4 {
            let avg = sorted.reduce(0, +) / Double(count)
            return formatDuration(avg)
        }

        let q1 = sorted[count / 4]
        let q3 = sorted[(count * 3) / 4]
        let iqr = q3 - q1
        let lower = q1 - 1.5 * iqr
        let upper = q3 + 1.5 * iqr

        let filtered = sorted.filter { $0 >= lower && $0 <= upper }
        guard !filtered.isEmpty else { return formatDuration(sorted.reduce(0, +) / Double(count)) }

        let avg = filtered.reduce(0, +) / Double(filtered.count)
        return formatDuration(avg)
    }

    static func workoutCount(for templateName: String, from workouts: [Workout]) -> Int {
        workouts.filter { $0.name == templateName && !$0.isInProgress }.count
    }

    private static func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(round(seconds / 60.0))
        return "\(minutes) min"
    }
}
