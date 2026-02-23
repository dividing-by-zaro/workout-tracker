import Foundation
import SwiftData

struct PreFillData {
    let weight: Double?
    let reps: Int?
    let distance: Double?
    let seconds: Double?
}

struct PreFillService {
    static func preFillSets(for exercise: Exercise, setCount: Int, in context: ModelContext) -> [PreFillData] {
        let exerciseId = exercise.persistentModelID
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
            if let workoutExercise = workout.exercises.first(where: { $0.exercise?.persistentModelID == exerciseId }) {
                let previousSets = workoutExercise.sortedSets
                if previousSets.isEmpty { continue }

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
