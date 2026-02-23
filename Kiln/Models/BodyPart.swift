import Foundation

enum BodyPart: String, Codable, CaseIterable {
    case chest, back, shoulders, arms, legs, core, cardio, fullBody, other

    var iconAsset: String {
        switch self {
        case .chest: return "bodypart_chest"
        case .back: return "bodypart_back"
        case .shoulders: return "bodypart_shoulders"
        case .arms: return "bodypart_arms"
        case .legs: return "bodypart_legs"
        case .core: return "bodypart_core"
        case .cardio: return "bodypart_cardio"
        case .fullBody: return "bodypart_full_body"
        case .other: return "bodypart_full_body"
        }
    }

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }

    static func infer(from exerciseName: String) -> BodyPart {
        let name = exerciseName.lowercased()

        // Chest
        if name.contains("bench press") || name.contains("chest") ||
           name.contains("pec") || name.contains("fly") || name.contains("flye") ||
           name.contains("push up") || name.contains("pushup") ||
           name.contains("dip") {
            return .chest
        }

        // Back
        if name.contains("row") || name.contains("pulldown") || name.contains("pull down") ||
           name.contains("lat ") || name.contains("deadlift") || name.contains("pull up") ||
           name.contains("pullup") || name.contains("chin up") || name.contains("chinup") ||
           name.contains("back") || name.contains("shrug") {
            return .back
        }

        // Shoulders
        if name.contains("shoulder") || name.contains("overhead press") ||
           name.contains("ohp") || name.contains("military press") ||
           name.contains("lateral raise") || name.contains("front raise") ||
           name.contains("face pull") || name.contains("delt") ||
           name.contains("arnold") {
            return .shoulders
        }

        // Arms
        if name.contains("curl") || name.contains("bicep") || name.contains("tricep") ||
           name.contains("hammer") || name.contains("extension") ||
           name.contains("pushdown") || name.contains("skull") ||
           name.contains("preacher") || name.contains("concentration") {
            return .arms
        }

        // Legs
        if name.contains("squat") || name.contains("leg") || name.contains("lunge") ||
           name.contains("calf") || name.contains("hamstring") || name.contains("quad") ||
           name.contains("glute") || name.contains("hip") || name.contains("split squat") ||
           name.contains("step up") || name.contains("rdl") ||
           name.contains("romanian") || name.contains("goblet") {
            return .legs
        }

        // Core
        if name.contains("ab") || name.contains("crunch") || name.contains("plank") ||
           name.contains("core") || name.contains("sit up") || name.contains("situp") ||
           name.contains("russian twist") || name.contains("leg raise") {
            return .core
        }

        // Cardio
        if name.contains("run") || name.contains("bike") || name.contains("cycle") ||
           name.contains("cardio") || name.contains("elliptical") || name.contains("treadmill") ||
           name.contains("rowing machine") || name.contains("stairmaster") ||
           name.contains("jump rope") || name.contains("burpee") {
            return .cardio
        }

        return .other
    }
}
