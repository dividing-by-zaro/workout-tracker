import Foundation
import SwiftData

struct PreFillData {
    let weight: Double?
    let reps: Int?
    let distance: Double?
    let seconds: Double?
}

struct PreFillRecommendation {
    let setCount: Int
    let preFillData: [PreFillData]
}

private struct HistoricalPreFillMatch {
    let setCount: Int
    let sourceSets: [WorkoutSet]?
}

struct PreFillService {
    static func recommendedSetCount(for exercise: Exercise, in context: ModelContext, defaultCount: Int = 3) -> Int {
        resolveHistoricalMatch(for: exercise, in: context, defaultCount: defaultCount)?.setCount ?? defaultCount
    }

    static func preFillSets(for exercise: Exercise, setCount: Int, in context: ModelContext) -> [PreFillData] {
        guard let match = resolveHistoricalMatch(for: exercise, in: context, defaultCount: setCount),
              let previousSets = match.sourceSets,
              !previousSets.isEmpty else {
            return defaultPreFill(count: setCount)
        }
        return preFillData(from: previousSets, setCount: setCount)
    }

    static func recommendation(for exercise: Exercise, in context: ModelContext, defaultCount: Int = 3) -> PreFillRecommendation {
        guard let match = resolveHistoricalMatch(for: exercise, in: context, defaultCount: defaultCount),
              let previousSets = match.sourceSets,
              !previousSets.isEmpty else {
            let fallback = defaultPreFill(count: defaultCount)
            return PreFillRecommendation(setCount: defaultCount, preFillData: fallback)
        }

        return PreFillRecommendation(
            setCount: match.setCount,
            preFillData: preFillData(from: previousSets, setCount: match.setCount)
        )
    }

    @discardableResult
    static func insertPrefilledExercise(_ exercise: Exercise, into workout: Workout, in context: ModelContext) -> WorkoutExercise {
        let workoutExercise = WorkoutExercise(order: workout.exercises.count, exercise: exercise, workout: workout)
        context.insert(workoutExercise)
        populatePrefillSets(for: exercise, on: workoutExercise, in: context)
        return workoutExercise
    }

    static func replacePrefilledExercise(_ workoutExercise: WorkoutExercise, with newExercise: Exercise, in context: ModelContext) {
        for set in workoutExercise.sets {
            context.delete(set)
        }
        workoutExercise.exercise = newExercise
        populatePrefillSets(for: newExercise, on: workoutExercise, in: context)
    }

    private static func fetchCompletedWorkouts(context: ModelContext) -> [Workout]? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isInProgress == false
            },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )
        return try? context.fetch(descriptor)
    }

    private static func resolveHistoricalMatch(for exercise: Exercise, in context: ModelContext, defaultCount: Int) -> HistoricalPreFillMatch? {
        let exerciseName = exercise.name
        guard let workouts = fetchCompletedWorkouts(context: context) else {
            return nil
        }

        var resolvedSetCount: Int?
        var sourceSets: [WorkoutSet]?

        for workout in workouts {
            guard let workoutExercise = workout.exercises.first(where: { $0.exercise?.name == exerciseName }) else {
                continue
            }

            let previousSets = workoutExercise.sortedSets
            if resolvedSetCount == nil, !previousSets.isEmpty {
                let completedSetCount = previousSets.filter(\.isCompleted).count
                resolvedSetCount = completedSetCount > 0 ? completedSetCount : previousSets.count
            }

            if sourceSets == nil, !previousSets.isEmpty {
                let hasMeaningfulData = previousSets.contains { set in
                    set.weight != nil || set.reps != nil || set.distance != nil || set.seconds != nil
                }
                if hasMeaningfulData {
                    sourceSets = previousSets
                }
            }

            if resolvedSetCount != nil && sourceSets != nil {
                break
            }
        }

        guard resolvedSetCount != nil || sourceSets != nil else {
            return nil
        }

        return HistoricalPreFillMatch(setCount: resolvedSetCount ?? defaultCount, sourceSets: sourceSets)
    }

    private static func populatePrefillSets(for exercise: Exercise, on workoutExercise: WorkoutExercise, in context: ModelContext) {
        let recommendation = recommendation(for: exercise, in: context)
        for (index, data) in recommendation.preFillData.enumerated() {
            let set = WorkoutSet(
                order: index,
                weight: data.weight,
                reps: data.reps,
                distance: data.distance,
                seconds: data.seconds,
                workoutExercise: workoutExercise
            )
            context.insert(set)
        }
    }

    private static func preFillData(from previousSets: [WorkoutSet], setCount: Int) -> [PreFillData] {
        (0..<setCount).map { index in
            let sourceSet = index < previousSets.count ? previousSets[index] : previousSets[previousSets.count - 1]
            return PreFillData(
                weight: sourceSet.weight,
                reps: sourceSet.reps,
                distance: sourceSet.distance,
                seconds: sourceSet.seconds
            )
        }
    }

    private static func defaultPreFill(count: Int) -> [PreFillData] {
        (0..<count).map { _ in PreFillData(weight: nil, reps: nil, distance: nil, seconds: nil) }
    }
}
