import SwiftUI

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
