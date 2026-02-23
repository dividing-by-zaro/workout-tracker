import Foundation

enum EquipmentType: String, Codable, CaseIterable {
    case barbell, dumbbell, kettlebell, machineOther
    case weightedBodyweight, repsOnly
    case duration, distance, weightedDistance

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .kettlebell: return "Kettlebell"
        case .machineOther: return "Machine/Other"
        case .weightedBodyweight: return "Weighted Bodyweight"
        case .repsOnly: return "Reps Only"
        case .duration: return "Duration"
        case .distance: return "Distance"
        case .weightedDistance: return "Weighted Distance"
        }
    }

    var tracksWeight: Bool {
        switch self {
        case .barbell, .dumbbell, .kettlebell, .machineOther, .weightedBodyweight, .weightedDistance:
            return true
        default:
            return false
        }
    }

    var tracksReps: Bool {
        switch self {
        case .barbell, .dumbbell, .kettlebell, .machineOther, .weightedBodyweight, .repsOnly:
            return true
        default:
            return false
        }
    }

    var tracksDistance: Bool {
        switch self {
        case .distance, .weightedDistance:
            return true
        default:
            return false
        }
    }

    var tracksDuration: Bool {
        self == .duration
    }

    static func infer(from exerciseName: String, fallback: ExerciseType) -> EquipmentType {
        let name = exerciseName.lowercased()

        // Check parenthetical equipment hints first
        if let parenRange = name.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            let paren = String(name[parenRange]).lowercased()
            if paren.contains("barbell") { return .barbell }
            if paren.contains("dumbbell") { return .dumbbell }
            if paren.contains("kettlebell") { return .kettlebell }
            if paren.contains("cable") || paren.contains("machine") || paren.contains("smith") ||
               paren.contains("lever") || paren.contains("band") { return .machineOther }
            if paren.contains("bodyweight") || paren.contains("assisted") { return .repsOnly }
        }

        // Keyword-based inference
        if name.contains("barbell") || name.contains("bench press") || name.contains("deadlift") ||
           name.contains("squat rack") || name.contains("overhead press") { return .barbell }
        if name.contains("dumbbell") || name.contains("db ") { return .dumbbell }
        if name.contains("kettlebell") || name.contains("kb ") { return .kettlebell }
        if name.contains("cable") || name.contains("machine") || name.contains("smith") ||
           name.contains("lat pulldown") || name.contains("leg press") || name.contains("lever") { return .machineOther }

        // Fall back to ExerciseType mapping
        switch fallback {
        case .strength:
            return .barbell
        case .cardio:
            return .duration
        case .bodyweight:
            return .repsOnly
        }
    }
}
