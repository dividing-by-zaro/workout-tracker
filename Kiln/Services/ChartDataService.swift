import Foundation
import SwiftData

struct ChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double
    var id: Date { date }
}

struct ExerciseHistorySession: Identifiable {
    let workout: Workout
    let workoutExercise: WorkoutExercise

    var id: UUID { workoutExercise.id }
}

struct TemplateHistorySummary {
    let averageDuration: String?
    let workoutCount: Int
}

struct HistoricalExerciseMatch {
    let recommendedSetCount: Int
    let sourceSets: [WorkoutSet]?
}

enum WorkoutHistoryService {
    static func fetchCompletedWorkouts(context: ModelContext) -> [Workout]? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isInProgress == false
            },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )
        return try? context.fetch(descriptor)
    }

    static func exerciseSessions(for exercise: Exercise, in workouts: [Workout]) -> [ExerciseHistorySession] {
        exerciseSessions(forExerciseId: exercise.id, in: workouts)
    }

    static func exerciseSessions(forExerciseId exerciseId: UUID, in workouts: [Workout]) -> [ExerciseHistorySession] {
        workouts
            .compactMap { workout in
                guard let workoutExercise = workout.exercises.first(where: { $0.exercise?.id == exerciseId }) else {
                    return nil
                }
                let hasCompletedSets = workoutExercise.sets.contains { $0.isCompleted }
                guard hasCompletedSets else { return nil }
                return ExerciseHistorySession(workout: workout, workoutExercise: workoutExercise)
            }
            .sorted { $0.workout.startedAt > $1.workout.startedAt }
    }

    static func mostRecentHistoricalMatch(
        forExerciseId exerciseId: UUID,
        in workouts: [Workout],
        defaultSetCount: Int
    ) -> HistoricalExerciseMatch? {
        var recommendedSetCount: Int?
        var sourceSets: [WorkoutSet]?

        for workout in workouts {
            guard let workoutExercise = workout.exercises.first(where: { $0.exercise?.id == exerciseId }) else {
                continue
            }

            let previousSets = workoutExercise.sortedSets
            if recommendedSetCount == nil, !previousSets.isEmpty {
                let completedSetCount = previousSets.filter(\.isCompleted).count
                recommendedSetCount = completedSetCount > 0 ? completedSetCount : previousSets.count
            }

            if sourceSets == nil, !previousSets.isEmpty {
                let hasMeaningfulData = previousSets.contains { set in
                    set.weight != nil || set.reps != nil || set.distance != nil || set.seconds != nil
                }
                if hasMeaningfulData {
                    sourceSets = previousSets
                }
            }

            if recommendedSetCount != nil && sourceSets != nil {
                break
            }
        }

        guard recommendedSetCount != nil || sourceSets != nil else { return nil }
        return HistoricalExerciseMatch(
            recommendedSetCount: recommendedSetCount ?? defaultSetCount,
            sourceSets: sourceSets
        )
    }

    static func templateSummary(for templateName: String, in workouts: [Workout]) -> TemplateHistorySummary {
        let durations = workouts
            .filter { $0.name == templateName && !$0.isInProgress && $0.durationSeconds != nil }
            .compactMap(\.durationSeconds)
            .map(Double.init)

        let averageDuration: String?
        if durations.isEmpty {
            averageDuration = nil
        } else {
            let sorted = durations.sorted()
            let count = sorted.count
            let average: Double

            if count < 4 {
                average = sorted.reduce(0, +) / Double(count)
            } else {
                let q1 = sorted[count / 4]
                let q3 = sorted[(count * 3) / 4]
                let iqr = q3 - q1
                let lower = q1 - 1.5 * iqr
                let upper = q3 + 1.5 * iqr
                let filtered = sorted.filter { $0 >= lower && $0 <= upper }
                average = (filtered.isEmpty ? sorted : filtered).reduce(0, +) / Double(filtered.isEmpty ? count : filtered.count)
            }

            averageDuration = formatDuration(average)
        }

        let workoutCount = workouts.filter { $0.name == templateName && !$0.isInProgress }.count
        return TemplateHistorySummary(averageDuration: averageDuration, workoutCount: workoutCount)
    }

    private static func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(round(seconds / 60.0))
        return "\(minutes) min"
    }
}

enum ChartDataService {
    /// Builds a time series for a given config from the provided completed workouts.
    /// Only workouts that contain the target exercise and fall inside the range
    /// contribute a point — no zero-filling.
    static func series(for config: ProfileChartConfig, workouts: [Workout], now: Date = .now) -> [ChartPoint] {
        guard let interval = config.range.dateInterval(
            now: now,
            customStart: config.customStart,
            customEnd: config.customEnd
        ) else { return [] }

        let sessions = WorkoutHistoryService.exerciseSessions(
            forExerciseId: config.exerciseId,
            in: workouts
        )

        var points: [ChartPoint] = []
        for session in sessions {
            let workout = session.workout
            guard let completedAt = workout.completedAt,
                  interval.contains(completedAt) else { continue }
            guard let value = config.metric.value(for: session.workoutExercise) else { continue }
            points.append(ChartPoint(date: completedAt, value: value))
        }
        return points.sorted { $0.date < $1.date }
    }
}
