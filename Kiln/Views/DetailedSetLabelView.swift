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
        if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                Text("+BW")
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                if let w = set.weight {
                    weightValue(w)
                }
                if let r = set.reps {
                    repsValue(r)
                }
                if let rpe = set.rpe {
                    rpeValue(rpe)
                }
            }
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight {
                    weightValue(w)
                }
                if let r = set.reps {
                    repsValue(r)
                }
                if let rpe = set.rpe {
                    rpeValue(rpe)
                }
            }
        } else if equipmentType == .repsOnly {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                Text("BW")
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                if let r = set.reps {
                    repsValue(r)
                }
            }
        } else if equipmentType == .weightedDistance {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight {
                    weightValue(w)
                }
                if let d = set.distance {
                    distanceValue(d)
                }
            }
        } else if equipmentType == .distance {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let d = set.distance {
                    distanceValue(d)
                }
            }
        } else if equipmentType == .duration {
            labelRow(spacing: DesignSystem.Spacing.sm) {
                if let s = set.seconds {
                    durationValue(s)
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
    }

    // MARK: - Value renderers

    @ViewBuilder
    private func weightValue(_ w: Double) -> some View {
        HStack(spacing: 2) {
            Text(formattedWeight(w))
                .font(DesignSystem.Typography.mono(15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)
            Text("lb")
                .font(DesignSystem.Typography.sans(11, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
    }

    @ViewBuilder
    private func repsValue(_ r: Int) -> some View {
        Text("\u{00D7} \(r)")
            .font(DesignSystem.Typography.mono(15, weight: .semibold))
            .foregroundStyle(DesignSystem.Colors.ink)
    }

    @ViewBuilder
    private func distanceValue(_ d: Double) -> some View {
        HStack(spacing: 2) {
            Text(String(format: "%.1f", d))
                .font(DesignSystem.Typography.mono(15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)
            Text("mi")
                .font(DesignSystem.Typography.sans(11, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
    }

    @ViewBuilder
    private func durationValue(_ s: Double) -> some View {
        HStack(spacing: 2) {
            Text(String(format: "%.0f", s))
                .font(DesignSystem.Typography.mono(15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)
            Text("s")
                .font(DesignSystem.Typography.sans(11, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
    }

    @ViewBuilder
    private func rpeValue(_ rpe: Double) -> some View {
        Text("RPE \(String(format: "%.0f", rpe))")
            .font(DesignSystem.Typography.helper)
            .foregroundStyle(DesignSystem.Colors.ink3)
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
