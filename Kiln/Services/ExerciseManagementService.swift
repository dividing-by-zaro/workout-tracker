import Foundation
import SwiftData

struct ExerciseMergeFieldPreview: Identifiable, Equatable {
    let field: String
    let sourceValue: String
    let targetValue: String
    let resultValue: String
    let decision: String

    var id: String { field }
}

struct ExerciseMergeWorkoutPreview: Identifiable, Equatable {
    let id: UUID
    let name: String
    let date: Date
    let isInProgress: Bool
    let hasSourceEntry: Bool
    let hasTargetEntry: Bool
    let sourceSetCount: Int
    let targetSetCount: Int

    var resultSetCount: Int { sourceSetCount + targetSetCount }
    var combinesExistingEntries: Bool { hasSourceEntry && hasTargetEntry }
}

struct ExerciseMergeTemplatePreview: Identifiable, Equatable {
    let id: UUID
    let name: String
    let sourceDefaultSets: Int
    let targetDefaultSets: Int?

    var resultDefaultSets: Int {
        max(sourceDefaultSets, targetDefaultSets ?? 0)
    }
}

struct ExerciseMergeChartPreview: Identifiable, Equatable {
    let id: UUID
    let metricName: String
    let rangeName: String
}

struct ExerciseMergedMetadata: Equatable {
    let exerciseType: ExerciseType
    let defaultRestSeconds: Int
    let bodyPart: BodyPart?
    let equipmentType: EquipmentType?
    let notes: String?
}

struct ExerciseMergePreview: Equatable {
    let sourceId: UUID
    let sourceName: String
    let sourceEquipmentName: String
    let targetId: UUID
    let targetName: String
    let targetEquipmentName: String
    let sourceLogCount: Int
    let targetLogCount: Int
    let overlappingLogCount: Int
    let resultingLogCount: Int
    let metadata: ExerciseMergedMetadata
    let fields: [ExerciseMergeFieldPreview]
    let workouts: [ExerciseMergeWorkoutPreview]
    let templates: [ExerciseMergeTemplatePreview]
    let charts: [ExerciseMergeChartPreview]

    var sourceLabel: String { "\(sourceName) (\(sourceEquipmentName))" }
    var targetLabel: String { "\(targetName) (\(targetEquipmentName))" }
}

struct ExerciseDeletionPreview {
    let completedLogCount: Int
    let workoutEntryCount: Int
    let setCount: Int
    let templateCount: Int
    let chartCount: Int
}

struct ExerciseMutationResult {
    let affectedFinishedWorkouts: [Workout]
    let removedExerciseIdentity: ExerciseRemoteIdentity?
}

struct ExerciseRemoteIdentity: Hashable, Codable {
    let name: String
    let equipmentTypeRaw: String?

    var storageKey: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return data.base64EncodedString()
    }

    init(name: String, equipmentType: EquipmentType?) {
        self.name = name
        self.equipmentTypeRaw = equipmentType?.rawValue
    }

    init?(storageKey: String) {
        guard let data = Data(base64Encoded: storageKey),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = decoded
    }
}

enum ExerciseManagementError: LocalizedError {
    case emptyName
    case duplicateIdentity
    case previewOutOfDate(ExerciseMergePreview)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Exercise name cannot be empty."
        case .duplicateIdentity:
            return "An exercise with that name and equipment type already exists."
        case .previewOutOfDate:
            return "Your exercise data changed. Review the refreshed preview before merging."
        }
    }
}

@MainActor
enum ExerciseManagementService {
    static func completedLogCount(for exercise: Exercise, in workouts: [Workout]) -> Int {
        completedWorkoutIds(for: exercise.id, in: workouts).count
    }

    static func deletionPreview(
        for exercise: Exercise,
        workouts: [Workout],
        templates: [WorkoutTemplate],
        charts: [ProfileChartConfig]
    ) -> ExerciseDeletionPreview {
        let workoutEntries = workouts.flatMap(\.exercises).filter { $0.exercise?.id == exercise.id }
        return ExerciseDeletionPreview(
            completedLogCount: completedLogCount(for: exercise, in: workouts),
            workoutEntryCount: workoutEntries.count,
            setCount: workoutEntries.reduce(0) { $0 + $1.sets.count },
            templateCount: templates.flatMap(\.exercises).filter { $0.exercise?.id == exercise.id }.count,
            chartCount: charts.filter { $0.exerciseId == exercise.id }.count
        )
    }

    static func rename(
        _ exercise: Exercise,
        to proposedName: String,
        allExercises: [Exercise],
        workouts: [Workout],
        charts: [ProfileChartConfig],
        context: ModelContext
    ) throws -> ExerciseMutationResult {
        let trimmed = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ExerciseManagementError.emptyName }
        // Renaming must not silently change an inferred equipment type just
        // because an equipment hint was removed from the name.
        let proposedEquipment = exercise.resolvedEquipmentType
        let proposedIdentity = Exercise.identityKey(name: trimmed, equipmentType: proposedEquipment)
        guard !allExercises.contains(where: {
            $0.id != exercise.id && $0.identityKey == proposedIdentity
        }) else {
            throw ExerciseManagementError.duplicateIdentity
        }

        let oldName = exercise.name
        let oldExplicitEquipment = exercise.equipmentType
        let oldRemoteIdentity = ExerciseRemoteIdentity(
            name: oldName,
            equipmentType: exercise.equipmentType
        )
        exercise.name = trimmed
        exercise.equipmentType = proposedEquipment
        let matchingCharts = charts.filter { $0.exerciseId == exercise.id }
        matchingCharts.forEach { $0.exerciseName = trimmed }

        do {
            try context.save()
        } catch {
            exercise.name = oldName
            exercise.equipmentType = oldExplicitEquipment
            matchingCharts.forEach { $0.exerciseName = oldName }
            throw error
        }

        return ExerciseMutationResult(
            affectedFinishedWorkouts: finishedWorkouts(containing: [exercise.id], in: workouts),
            removedExerciseIdentity: oldName == trimmed ? nil : oldRemoteIdentity
        )
    }

    static func makeMergePreview(
        source: Exercise,
        target: Exercise,
        workouts: [Workout],
        templates: [WorkoutTemplate],
        charts: [ProfileChartConfig]
    ) -> ExerciseMergePreview {
        let metadata = mergedMetadata(source: source, target: target)
        let sourceCompletedIds = completedWorkoutIds(for: source.id, in: workouts)
        let targetCompletedIds = completedWorkoutIds(for: target.id, in: workouts)

        let workoutPreviews = workouts.compactMap { workout -> ExerciseMergeWorkoutPreview? in
            let sourceEntries = workout.exercises.filter { $0.exercise?.id == source.id }
            let targetEntries = workout.exercises.filter { $0.exercise?.id == target.id }
            guard !sourceEntries.isEmpty || !targetEntries.isEmpty else { return nil }
            return ExerciseMergeWorkoutPreview(
                id: workout.id,
                name: workout.name,
                date: workout.startedAt,
                isInProgress: workout.isInProgress,
                hasSourceEntry: !sourceEntries.isEmpty,
                hasTargetEntry: !targetEntries.isEmpty,
                sourceSetCount: sourceEntries.reduce(0) { $0 + $1.sets.count },
                targetSetCount: targetEntries.reduce(0) { $0 + $1.sets.count }
            )
        }.sorted { $0.date > $1.date }

        let templatePreviews = templates.compactMap { template -> ExerciseMergeTemplatePreview? in
            guard let sourceEntry = template.exercises.first(where: { $0.exercise?.id == source.id }) else {
                return nil
            }
            let targetEntry = template.exercises.first(where: { $0.exercise?.id == target.id })
            return ExerciseMergeTemplatePreview(
                id: template.id,
                name: template.name,
                sourceDefaultSets: sourceEntry.defaultSets,
                targetDefaultSets: targetEntry?.defaultSets
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let chartPreviews = charts.filter { $0.exerciseId == source.id }.map {
            ExerciseMergeChartPreview(
                id: $0.id,
                metricName: $0.metric.displayName,
                rangeName: $0.range.displayName
            )
        }.sorted { $0.id.uuidString < $1.id.uuidString }

        return ExerciseMergePreview(
            sourceId: source.id,
            sourceName: source.name,
            sourceEquipmentName: source.resolvedEquipmentType.displayName,
            targetId: target.id,
            targetName: target.name,
            targetEquipmentName: target.resolvedEquipmentType.displayName,
            sourceLogCount: sourceCompletedIds.count,
            targetLogCount: targetCompletedIds.count,
            overlappingLogCount: sourceCompletedIds.intersection(targetCompletedIds).count,
            resultingLogCount: sourceCompletedIds.union(targetCompletedIds).count,
            metadata: metadata,
            fields: metadataFields(source: source, target: target, result: metadata),
            workouts: workoutPreviews,
            templates: templatePreviews,
            charts: chartPreviews
        )
    }

    static func merge(
        source: Exercise,
        into target: Exercise,
        preview: ExerciseMergePreview,
        workouts: [Workout],
        templates: [WorkoutTemplate],
        charts: [ProfileChartConfig],
        context: ModelContext
    ) throws -> ExerciseMutationResult {
        let currentPreview = makeMergePreview(
            source: source,
            target: target,
            workouts: workouts,
            templates: templates,
            charts: charts
        )
        guard currentPreview == preview else {
            throw ExerciseManagementError.previewOutOfDate(currentPreview)
        }

        target.exerciseType = preview.metadata.exerciseType
        target.defaultRestSeconds = preview.metadata.defaultRestSeconds
        target.bodyPart = preview.metadata.bodyPart
        target.equipmentType = preview.metadata.equipmentType
        target.notes = preview.metadata.notes

        let affectedFinishedWorkouts = finishedWorkouts(
            containing: [source.id, target.id],
            in: workouts
        )

        for workout in workouts {
            let matchingEntries = workout.sortedExercises.filter {
                $0.exercise?.id == source.id || $0.exercise?.id == target.id
            }
            guard matchingEntries.contains(where: { $0.exercise?.id == source.id }) else { continue }

            let keeper = matchingEntries.first(where: { $0.exercise?.id == target.id }) ?? matchingEntries[0]
            let earliestOrder = matchingEntries.map(\.order).min() ?? keeper.order
            let orderedSets = matchingEntries.flatMap(\.sortedSets)
            let removedIds = Set(matchingEntries.filter { $0.id != keeper.id }.map(\.id))

            keeper.exercise = target
            keeper.order = earliestOrder
            for (index, set) in orderedSets.enumerated() {
                set.workoutExercise = keeper
                set.order = index
            }
            for entry in matchingEntries where entry.id != keeper.id {
                entry.sets.removeAll()
                context.delete(entry)
            }
            keeper.sets = orderedSets

            let remaining = workout.exercises
                .filter { !removedIds.contains($0.id) }
                .sorted { $0.order < $1.order }
            for (index, entry) in remaining.enumerated() {
                entry.order = index
            }
        }

        for template in templates {
            let matchingEntries = template.sortedExercises.filter {
                $0.exercise?.id == source.id || $0.exercise?.id == target.id
            }
            guard matchingEntries.contains(where: { $0.exercise?.id == source.id }) else { continue }

            let keeper = matchingEntries.first(where: { $0.exercise?.id == target.id }) ?? matchingEntries[0]
            let removedIds = Set(matchingEntries.filter { $0.id != keeper.id }.map(\.id))
            keeper.exercise = target
            keeper.order = matchingEntries.map(\.order).min() ?? keeper.order
            keeper.defaultSets = matchingEntries.map(\.defaultSets).max() ?? keeper.defaultSets
            for entry in matchingEntries where entry.id != keeper.id {
                context.delete(entry)
            }

            let remaining = template.exercises
                .filter { !removedIds.contains($0.id) }
                .sorted { $0.order < $1.order }
            for (index, entry) in remaining.enumerated() {
                entry.order = index
            }
        }

        for chart in charts where chart.exerciseId == source.id || chart.exerciseId == target.id {
            chart.exerciseId = target.id
            chart.exerciseName = target.name
        }

        let removedName = source.name
        let removedIdentity = ExerciseRemoteIdentity(
            name: removedName,
            equipmentType: source.equipmentType
        )
        context.delete(source)
        try context.save()

        return ExerciseMutationResult(
            affectedFinishedWorkouts: affectedFinishedWorkouts,
            removedExerciseIdentity: removedIdentity
        )
    }

    static func delete(
        _ exercise: Exercise,
        workouts: [Workout],
        templates: [WorkoutTemplate],
        charts: [ProfileChartConfig],
        context: ModelContext
    ) throws -> ExerciseMutationResult {
        let affected = finishedWorkouts(containing: [exercise.id], in: workouts)
        let exerciseId = exercise.id
        let removedName = exercise.name
        let removedIdentity = ExerciseRemoteIdentity(
            name: removedName,
            equipmentType: exercise.equipmentType
        )

        for workout in workouts {
            let removedIds = Set(workout.exercises.filter { $0.exercise?.id == exerciseId }.map(\.id))
            guard !removedIds.isEmpty else { continue }
            for entry in workout.exercises where removedIds.contains(entry.id) {
                context.delete(entry)
            }
            let remaining = workout.exercises
                .filter { !removedIds.contains($0.id) }
                .sorted { $0.order < $1.order }
            for (index, entry) in remaining.enumerated() {
                entry.order = index
            }
        }

        for template in templates {
            let removedIds = Set(template.exercises.filter { $0.exercise?.id == exerciseId }.map(\.id))
            guard !removedIds.isEmpty else { continue }
            for entry in template.exercises where removedIds.contains(entry.id) {
                context.delete(entry)
            }
            let remaining = template.exercises
                .filter { !removedIds.contains($0.id) }
                .sorted { $0.order < $1.order }
            for (index, entry) in remaining.enumerated() {
                entry.order = index
            }
        }

        for chart in charts where chart.exerciseId == exerciseId {
            context.delete(chart)
        }

        context.delete(exercise)
        try context.save()

        return ExerciseMutationResult(
            affectedFinishedWorkouts: affected,
            removedExerciseIdentity: removedIdentity
        )
    }

    // MARK: - Metadata merge rules

    private static func mergedMetadata(source: Exercise, target: Exercise) -> ExerciseMergedMetadata {
        // Equipment is part of exercise identity, so merging into a destination
        // must never change that destination's effective equipment type.
        let equipment = target.resolvedEquipmentType
        let type = exerciseType(for: equipment, fallback: target.exerciseType)

        let rest: Int
        if target.defaultRestSeconds == source.defaultRestSeconds {
            rest = target.defaultRestSeconds
        } else if target.defaultRestSeconds == 120 && source.defaultRestSeconds != 120 {
            rest = source.defaultRestSeconds
        } else {
            rest = target.defaultRestSeconds
        }

        return ExerciseMergedMetadata(
            exerciseType: type,
            defaultRestSeconds: rest,
            bodyPart: target.bodyPart ?? source.bodyPart,
            equipmentType: equipment,
            notes: mergedNotes(source: source, target: target)
        )
    }

    private static func metadataFields(
        source: Exercise,
        target: Exercise,
        result: ExerciseMergedMetadata
    ) -> [ExerciseMergeFieldPreview] {
        [
            ExerciseMergeFieldPreview(
                field: "Name",
                sourceValue: source.name,
                targetValue: target.name,
                resultValue: target.name,
                decision: "The destination exercise name is kept."
            ),
            ExerciseMergeFieldPreview(
                field: "Exercise type",
                sourceValue: display(source.exerciseType),
                targetValue: display(target.exerciseType),
                resultValue: display(result.exerciseType),
                decision: source.exerciseType == target.exerciseType
                    ? "Both exercises agree."
                    : "The internal exercise type is aligned with the destination equipment."
            ),
            ExerciseMergeFieldPreview(
                field: "Equipment",
                sourceValue: source.resolvedEquipmentType.displayName,
                targetValue: target.resolvedEquipmentType.displayName,
                resultValue: result.equipmentType?.displayName ?? target.resolvedEquipmentType.displayName,
                decision: "Equipment is part of exercise identity, so the destination value is always kept."
            ),
            ExerciseMergeFieldPreview(
                field: "Body part",
                sourceValue: source.bodyPart?.displayName ?? "Not explicitly set",
                targetValue: target.bodyPart?.displayName ?? "Not explicitly set",
                resultValue: result.bodyPart?.displayName ?? "Not explicitly set",
                decision: optionalFieldDecision(
                    sourceIsSet: source.bodyPart != nil,
                    targetIsSet: target.bodyPart != nil
                )
            ),
            ExerciseMergeFieldPreview(
                field: "Rest timer",
                sourceValue: formatRest(source.defaultRestSeconds),
                targetValue: formatRest(target.defaultRestSeconds),
                resultValue: formatRest(result.defaultRestSeconds),
                decision: restDecision(source: source, target: target)
            ),
            ExerciseMergeFieldPreview(
                field: "Notes",
                sourceValue: normalizedNote(source.notes) ?? "None",
                targetValue: normalizedNote(target.notes) ?? "None",
                resultValue: result.notes ?? "None",
                decision: notesDecision(source: source, target: target)
            )
        ]
    }

    private static func mergedNotes(source: Exercise, target: Exercise) -> String? {
        let sourceNote = normalizedNote(source.notes)
        let targetNote = normalizedNote(target.notes)
        switch (sourceNote, targetNote) {
        case (nil, nil): return nil
        case (let source?, nil): return source
        case (nil, let target?): return target
        case (let sourceText?, let targetText?) where sourceText == targetText: return targetText
        case (let sourceText?, let targetText?):
            return "\(targetText)\n\n— Merged from \(source.name) —\n\(sourceText)"
        }
    }

    private static func notesDecision(source: Exercise, target: Exercise) -> String {
        let sourceNote = normalizedNote(source.notes)
        let targetNote = normalizedNote(target.notes)
        if sourceNote == nil && targetNote == nil { return "Neither exercise has notes." }
        if sourceNote == nil { return "Only the destination note is kept." }
        if targetNote == nil { return "The source note is carried over." }
        if sourceNote == targetNote { return "The duplicate note is kept once." }
        return "Both notes are preserved, with the source note labeled."
    }

    private static func optionalFieldDecision(sourceIsSet: Bool, targetIsSet: Bool) -> String {
        switch (sourceIsSet, targetIsSet) {
        case (false, false): return "Neither exercise has an explicit value, so inference remains available."
        case (true, false): return "The destination was blank, so the source value is carried over."
        case (_, true): return "The destination value is kept."
        }
    }

    private static func restDecision(source: Exercise, target: Exercise) -> String {
        if source.defaultRestSeconds == target.defaultRestSeconds {
            return "Both exercises agree."
        }
        if target.defaultRestSeconds == 120 && source.defaultRestSeconds != 120 {
            return "The destination used the 2-minute default, so the customized source timer is carried over."
        }
        return "The destination's customized timer is kept."
    }

    private static func normalizedNote(_ note: String?) -> String? {
        guard let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func exerciseType(for equipment: EquipmentType, fallback: ExerciseType) -> ExerciseType {
        if equipment == .repsOnly { return .bodyweight }
        if equipment.tracksDistance || equipment.tracksDuration { return .cardio }
        if equipment.tracksWeight || equipment.tracksReps { return .strength }
        return fallback
    }

    private static func display(_ type: ExerciseType) -> String {
        type.rawValue.capitalized
    }

    private static func formatRest(_ seconds: Int) -> String {
        if seconds % 60 == 0 { return "\(seconds / 60) min" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }

    private static func completedWorkoutIds(for exerciseId: UUID, in workouts: [Workout]) -> Set<UUID> {
        Set(workouts.compactMap { workout in
            guard !workout.isInProgress,
                  workout.exercises.contains(where: {
                      $0.exercise?.id == exerciseId && $0.sets.contains(where: \.isCompleted)
                  }) else { return nil }
            return workout.id
        })
    }

    private static func finishedWorkouts(containing exerciseIds: Set<UUID>, in workouts: [Workout]) -> [Workout] {
        workouts.filter { workout in
            !workout.isInProgress && workout.exercises.contains(where: {
                guard let id = $0.exercise?.id else { return false }
                return exerciseIds.contains(id)
            })
        }
    }
}
