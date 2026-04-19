import Foundation

extension Double {
    var formattedWeight: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}

/// Shared formatters for workout set labels.
///
/// `summaryLabel` produces the compact set-summary strings shown in the
/// Live Activity (e.g. `"8×135"`, `"×12"`, `"45s"`, `"1.2mi"`, `"135•1.2mi"`).
/// This is the format used by both `LiveActivityService` and `LiveActivityCache`
/// so pending in-memory edits on the lock screen match what the app would
/// render when it next rebuilds the content state.
enum SetFormatter {
    /// Build the compact summary label for a set.
    /// - Parameters:
    ///   - equipmentCategory: raw category string from `EquipmentType.equipmentCategory`
    ///   - weight: weight in lbs (if tracked)
    ///   - reps: rep count (if tracked)
    ///   - seconds: duration in seconds (if tracked)
    ///   - distance: distance in miles (if tracked)
    static func summaryLabel(
        equipmentCategory: String,
        weight: Double?,
        reps: Int?,
        seconds: Double?,
        distance: Double?
    ) -> String {
        switch equipmentCategory {
        case "weightReps":
            let r = reps ?? 0
            let w = (weight ?? 0).formattedWeight
            return "\(r)×\(w)"
        case "repsOnly":
            return "×\(reps ?? 0)"
        case "duration":
            return "\(Int(seconds ?? 0))s"
        case "distance":
            return "\(String(format: "%.1f", distance ?? 0))mi"
        case "weightDistance":
            let w = (weight ?? 0).formattedWeight
            return "\(w)•\(String(format: "%.1f", distance ?? 0))mi"
        default:
            return "—"
        }
    }
}
