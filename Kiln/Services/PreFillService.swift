import Foundation
import SwiftData

struct PreFillData {
    let weight: Double?
    let reps: Int?
    let distance: Double?
    let seconds: Double?
}

struct PreFillService {
    static func recommendedSetCount(for exercise: Exercise, in context: ModelContext, defaultCount: Int = 3) -> Int {
        let exerciseName = exercise.name
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isInProgress == false
            },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )

        guard let workouts = try? context.fetch(descriptor) else {
            return defaultCount
        }

        for workout in workouts {
            guard let workoutExercise = workout.exercises.first(where: { $0.exercise?.name == exerciseName }) else {
                continue
            }

            let completedSetCount = workoutExercise.sortedSets.filter(\.isCompleted).count
            if completedSetCount > 0 {
                return completedSetCount
            }

            if !workoutExercise.sortedSets.isEmpty {
                return workoutExercise.sortedSets.count
            }
        }

        return defaultCount
    }

    static func preFillSets(for exercise: Exercise, setCount: Int, in context: ModelContext) -> [PreFillData] {
        let exerciseName = exercise.name
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isInProgress == false
            },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )

        guard let workouts = try? context.fetch(descriptor) else {
            return defaultPreFill(count: setCount)
        }

        for workout in workouts {
            if let workoutExercise = workout.exercises.first(where: { $0.exercise?.name == exerciseName }) {
                let previousSets = workoutExercise.sortedSets
                if previousSets.isEmpty { continue }

                // Only use this workout if at least one set has meaningful data
                let hasData = previousSets.contains { set in
                    set.weight != nil || set.reps != nil || set.distance != nil || set.seconds != nil
                }
                if !hasData { continue }

                return (0..<setCount).map { index in
                    let sourceSet = index < previousSets.count ? previousSets[index] : previousSets[previousSets.count - 1]
                    return PreFillData(
                        weight: sourceSet.weight,
                        reps: sourceSet.reps,
                        distance: sourceSet.distance,
                        seconds: sourceSet.seconds
                    )
                }
            }
        }

        return defaultPreFill(count: setCount)
    }

    private static func defaultPreFill(count: Int) -> [PreFillData] {
        (0..<count).map { _ in PreFillData(weight: nil, reps: nil, distance: nil, seconds: nil) }
    }
}
