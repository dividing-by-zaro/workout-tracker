import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var workoutSet: WorkoutSet
    let equipmentType: EquipmentType
    let previousData: PreFillData?
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Full-row tappable background
            RoundedRectangle(cornerRadius: 6)
                .fill(workoutSet.isCompleted ? DesignSystem.Colors.success.opacity(0.1) : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { onComplete() }

            // Content centered in the row
            HStack(spacing: DesignSystem.Spacing.md) {
                Group {
                    if workoutSet.isCompleted {
                        Image("brick_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
                .frame(width: 20)
                .allowsHitTesting(false)
                previousLabel
                    .frame(width: 60, alignment: .center)
                    .allowsHitTesting(false)
                inputFields
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .opacity(workoutSet.isCompleted ? 0.7 : 1.0)
    }

    @ViewBuilder
    private var previousLabel: some View {
        if let prev = previousData {
            if equipmentType.tracksWeight && equipmentType.tracksReps {
                if let w = prev.weight, let r = prev.reps {
                    Text("\(Int(w)) lbs x \(r)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else if let w = prev.weight {
                    Text("\(Int(w)) lbs")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    dashLabel
                }
            } else if equipmentType.tracksReps && !equipmentType.tracksWeight {
                if let r = prev.reps {
                    Text("x \(r)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    dashLabel
                }
            } else if equipmentType.tracksDistance {
                if let d = prev.distance {
                    Text(String(format: "%.1f mi", d))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    dashLabel
                }
            } else if equipmentType.tracksDuration {
                if let s = prev.seconds {
                    Text(String(format: "%.0fs", s))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    dashLabel
                }
            } else {
                dashLabel
            }
        } else {
            dashLabel
        }
    }

    private var dashLabel: some View {
        Text("—")
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    @ViewBuilder
    private var inputFields: some View {
        if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("+BW")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 30)
                    .allowsHitTesting(false)
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType == .repsOnly {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("BW")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 60)
                    .allowsHitTesting(false)
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType == .weightedDistance {
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                NumericField(value: $workoutSet.distance, placeholder: "mi")
            }
        } else if equipmentType == .distance {
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.distance, placeholder: "mi")
            }
        } else if equipmentType == .duration {
            HStack(spacing: DesignSystem.Spacing.xs) {
                IntSeconds(value: $workoutSet.seconds, placeholder: "sec")
            }
        }
    }
}

// MARK: - Numeric Input Helpers

private struct NumericField: View {
    @Binding var value: Double?
    let placeholder: String

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)
            .font(DesignSystem.Typography.body)
    }
}

private struct IntField: View {
    @Binding var value: Int?
    let placeholder: String

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)
            .font(DesignSystem.Typography.body)
    }
}

private struct IntSeconds: View {
    @Binding var value: Double?
    let placeholder: String

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)
            .font(DesignSystem.Typography.body)
    }
}
