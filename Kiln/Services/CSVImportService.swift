import Foundation
import SwiftData

struct CSVImportResult: Sendable {
    let workoutsCreated: Int
    let rowsImported: Int
    let rowsSkipped: Int
    let exercisesCreated: Int
    let templatesCreated: Int
}

@ModelActor
actor CSVImportService {

    func importCSV(_ csvContent: String) -> CSVImportResult {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { return CSVImportResult(workoutsCreated: 0, rowsImported: 0, rowsSkipped: 0, exercisesCreated: 0, templatesCreated: 0) }

        var exerciseCache: [String: Exercise] = [:]
        var workoutGroups: [(key: String, rows: [[String]])] = []
        var currentKey = ""
        var currentRows: [[String]] = []
        var rowsSkipped = 0
        var rowsImported = 0
        var exercisesCreated = 0

        // Load existing exercises
        if let existing = try? modelContext.fetch(FetchDescriptor<Exercise>()) {
            for ex in existing { exerciseCache[ex.name] = ex }
        }

        // Parse CSV (skip header)
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            let fields = parseCSVLine(line)
            guard fields.count >= 10 else { rowsSkipped += 1; continue }

            let dateStr = fields[0]
            let workoutName = fields[1]
            let key = "\(dateStr)|\(workoutName)"

            if key != currentKey {
                if !currentKey.isEmpty {
                    workoutGroups.append((key: currentKey, rows: currentRows))
                }
                currentKey = key
                currentRows = []
            }
            currentRows.append(fields)
            rowsImported += 1
        }
        if !currentKey.isEmpty {
            workoutGroups.append((key: currentKey, rows: currentRows))
        }

        // Create workouts
        var workoutsCreated = 0
        var recentWorkoutsByName: [String: Workout] = [:]

        for group in workoutGroups {
            let fields = group.rows[0]
            let dateStr = fields[0]
            let workoutName = fields[1]
            let durationStr = fields[2]

            guard let startDate = parseDate(dateStr) else { continue }
            let durationSec = parseDuration(durationStr)
            let completedDate = startDate.addingTimeInterval(Double(durationSec))

            let workout = Workout(
                name: workoutName,
                startedAt: startDate,
                completedAt: completedDate,
                durationSeconds: durationSec,
                isInProgress: false
            )
            modelContext.insert(workout)
            recentWorkoutsByName[workoutName] = workout

            // Group rows by exercise name
            var exerciseGroups: [(name: String, rows: [[String]])] = []
            var currentExName = ""
            var currentExRows: [[String]] = []

            for row in group.rows {
                let exName = row[3]
                if exName != currentExName {
                    if !currentExName.isEmpty {
                        exerciseGroups.append((name: currentExName, rows: currentExRows))
                    }
                    currentExName = exName
                    currentExRows = []
                }
                currentExRows.append(row)
            }
            if !currentExName.isEmpty {
                exerciseGroups.append((name: currentExName, rows: currentExRows))
            }

            for (exIndex, exGroup) in exerciseGroups.enumerated() {
                let exercise: Exercise
                if let cached = exerciseCache[exGroup.name] {
                    exercise = cached
                } else {
                    let firstRow = exGroup.rows[0]
                    let bodyPart = firstRow.count > 10 ? BodyPart(rawValue: firstRow[10]) : nil
                    let equipType = firstRow.count > 11 ? EquipmentType(rawValue: firstRow[11]) : nil
                    let resolvedEquip = equipType ?? .barbell
                    let exType: ExerciseType = resolvedEquip.tracksWeight ? .strength :
                        (resolvedEquip == .repsOnly ? .bodyweight : .cardio)
                    exercise = Exercise(
                        name: exGroup.name,
                        exerciseType: exType,
                        bodyPart: bodyPart,
                        equipmentType: equipType
                    )
                    modelContext.insert(exercise)
                    exerciseCache[exGroup.name] = exercise
                    exercisesCreated += 1
                }

                let workoutExercise = WorkoutExercise(order: exIndex, exercise: exercise, workout: workout)
                modelContext.insert(workoutExercise)

                for row in exGroup.rows {
                    let setOrder = (Int(row[4]) ?? 1) - 1
                    let weight = Double(row[5])
                    let reps = Int(row[6])
                    let distance = Double(row[7])
                    let seconds = Double(row[8])
                    let rpe = Double(row[9])

                    let workoutSet = WorkoutSet(
                        order: setOrder,
                        weight: weight,
                        reps: reps,
                        distance: distance,
                        seconds: seconds,
                        rpe: rpe,
                        isCompleted: true,
                        completedAt: workout.completedAt,
                        workoutExercise: workoutExercise
                    )
                    modelContext.insert(workoutSet)
                }
            }

            workoutsCreated += 1

            // Batch save every 50 workouts
            if workoutsCreated % 50 == 0 {
                try? modelContext.save()
            }
        }

        // Auto-create templates for the two specified workout names
        let templateNames = ["New Legs/full Body A", "New Legs/full Body B"]
        var templatesCreated = 0

        for templateName in templateNames {
            guard let recentWorkout = recentWorkoutsByName[templateName] else { continue }

            // Check if template already exists
            let existingDescriptor = FetchDescriptor<WorkoutTemplate>(
                predicate: #Predicate<WorkoutTemplate> { $0.name == templateName }
            )
            if let existing = try? modelContext.fetch(existingDescriptor), !existing.isEmpty { continue }

            let template = WorkoutTemplate(name: templateName, lastUsedAt: recentWorkout.startedAt)
            modelContext.insert(template)

            for workoutExercise in recentWorkout.sortedExercises {
                guard let exercise = workoutExercise.exercise else { continue }
                let templateExercise = TemplateExercise(
                    order: workoutExercise.order,
                    defaultSets: workoutExercise.sets.count,
                    exercise: exercise,
                    template: template
                )
                modelContext.insert(templateExercise)
            }
            templatesCreated += 1
        }

        try? modelContext.save()

        return CSVImportResult(
            workoutsCreated: workoutsCreated,
            rowsImported: rowsImported,
            rowsSkipped: rowsSkipped,
            exercisesCreated: exercisesCreated,
            templatesCreated: templatesCreated
        )
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    private func parseDate(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: dateStr) { return date }
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }

    private func parseDuration(_ durationStr: String) -> Int {
        let cleaned = durationStr.trimmingCharacters(in: .whitespaces)
        var totalSeconds = 0

        let hourPattern = /(\d+)h/
        let minPattern = /(\d+)m/
        let secPattern = /(\d+)s/

        if let match = cleaned.firstMatch(of: hourPattern) {
            totalSeconds += (Int(match.1) ?? 0) * 3600
        }
        if let match = cleaned.firstMatch(of: minPattern) {
            totalSeconds += (Int(match.1) ?? 0) * 60
        }
        if let match = cleaned.firstMatch(of: secPattern) {
            totalSeconds += Int(match.1) ?? 0
        }

        return totalSeconds
    }

}
