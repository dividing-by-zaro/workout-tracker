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

struct PreFillService {
    static func recommendedSetCount(for exercise: Exercise, in context: ModelContext, defaultCount: Int = 3) -> Int {
        let workouts = WorkoutHistoryService.fetchCompletedWorkouts(context: context) ?? []
        return recommendedSetCount(for: exercise, in: workouts, defaultCount: defaultCount)
    }

    static func preFillSets(for exercise: Exercise, setCount: Int, in context: ModelContext) -> [PreFillData] {
        let workouts = WorkoutHistoryService.fetchCompletedWorkouts(context: context) ?? []
        return preFillSets(for: exercise, setCount: setCount, in: workouts)
    }

    static func recommendation(for exercise: Exercise, in context: ModelContext, defaultCount: Int = 3) -> PreFillRecommendation {
        let workouts = WorkoutHistoryService.fetchCompletedWorkouts(context: context) ?? []
        return recommendation(for: exercise, in: workouts, defaultCount: defaultCount)
    }

    static func recommendedSetCount(for exercise: Exercise, in workouts: [Workout], defaultCount: Int = 3) -> Int {
        recommendation(for: exercise, in: workouts, defaultCount: defaultCount).setCount
    }

    static func preFillSets(for exercise: Exercise, setCount: Int, in workouts: [Workout]) -> [PreFillData] {
        guard let match = WorkoutHistoryService.mostRecentHistoricalMatch(
            forExerciseId: exercise.id,
            in: workouts,
            defaultSetCount: setCount
        ),
        let sourceSets = match.sourceSets
        else {
            return defaultPreFill(count: setCount)
        }

        return preFillData(from: sourceSets, setCount: setCount)
    }

    static func recommendation(for exercise: Exercise, in workouts: [Workout], defaultCount: Int = 3) -> PreFillRecommendation {
        guard let match = WorkoutHistoryService.mostRecentHistoricalMatch(
            forExerciseId: exercise.id,
            in: workouts,
            defaultSetCount: defaultCount
        ) else {
            let fallback = defaultPreFill(count: defaultCount)
            return PreFillRecommendation(setCount: defaultCount, preFillData: fallback)
        }

        guard let sourceSets = match.sourceSets else {
            return PreFillRecommendation(
                setCount: match.recommendedSetCount,
                preFillData: defaultPreFill(count: match.recommendedSetCount)
            )
        }

        return PreFillRecommendation(
            setCount: match.recommendedSetCount,
            preFillData: preFillData(from: sourceSets, setCount: match.recommendedSetCount)
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
