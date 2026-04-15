import Foundation
import SwiftUI

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
///
/// `DetailedSetLabelView` centralizes the more detailed set labels used in the
/// workout detail and exercise history screens while preserving each screen's
/// existing copy choices.
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

/// Shared detailed set label UI used by workout history/detail screens.
struct DetailedSetLabelView: View {
    enum WeightFormatting {
        case integer
        case formatted
    }

    enum Style {
        case workoutDetail
        case exerciseHistory

        var weightFormatting: WeightFormatting {
            switch self {
            case .workoutDetail:
                return .integer
            case .exerciseHistory:
                return .formatted
            }
        }
    }

    let set: WorkoutSet
    let equipmentType: EquipmentType
    let style: Style

    var body: some View {
        let bodyStyle = DesignSystem.Typography.body
        let captionStyle = DesignSystem.Typography.caption

        if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                Text("+BW").font(bodyStyle).foregroundStyle(DesignSystem.Colors.textSecondary)
                if let w = set.weight {
                    Text("\(formattedWeight(w)) lb").font(bodyStyle)
                }
                if let r = set.reps {
                    Text("x \(r)").font(bodyStyle)
                }
                if let rpe = set.rpe {
                    Text("RPE \(String(format: "%.0f", rpe))")
                        .font(captionStyle)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight {
                    Text("\(formattedWeight(w)) lb").font(bodyStyle)
                }
                if let r = set.reps {
                    Text("x \(r)").font(bodyStyle)
                }
                if let rpe = set.rpe {
                    Text("RPE \(String(format: "%.0f", rpe))")
                        .font(captionStyle)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        } else if equipmentType == .repsOnly {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                Text("BW").font(bodyStyle).foregroundStyle(DesignSystem.Colors.textSecondary)
                if let r = set.reps {
                    Text("x \(r)").font(bodyStyle)
                }
            }
        } else if equipmentType == .weightedDistance {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight {
                    Text("\(formattedWeight(w)) lb").font(bodyStyle)
                }
                if let d = set.distance {
                    Text(String(format: "%.1f mi", d)).font(bodyStyle)
                }
            }
        } else if equipmentType == .distance {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let d = set.distance {
                    Text(String(format: "%.1f mi", d)).font(bodyStyle)
                }
            }
        } else if equipmentType == .duration {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let s = set.seconds {
                    Text(String(format: "%.0fs", s)).font(bodyStyle)
                }
            }
        }
    }

    @ViewBuilder
    private func labelRow<Content: View>(
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: spacing) {
            content()
        }
        .foregroundStyle(DesignSystem.Colors.textPrimary)
    }

    private func formattedWeight(_ weight: Double) -> String {
        switch style.weightFormatting {
        case .integer:
            return String(Int(weight))
        case .formatted:
            return weight.formattedWeight
        }
    }
}
