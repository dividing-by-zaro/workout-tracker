import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var workoutSet: WorkoutSet
    let setNumber: Int
    let equipmentType: EquipmentType
    let previousData: PreFillData?
    var onComplete: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Text("\(setNumber)")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 28)

            previousLabel
                .frame(width: 80, alignment: .leading)

            inputFields

            Spacer()

            Button(action: {
                onComplete()
            }) {
                Image(systemName: workoutSet.isCompleted ? DesignSystem.Icon.checkmark : "circle")
                    .font(.title2)
                    .foregroundStyle(workoutSet.isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .opacity(workoutSet.isCompleted ? 0.7 : 1.0)
    }

    @ViewBuilder
    private var previousLabel: some View {
        if let prev = previousData {
            if equipmentType.tracksWeight && equipmentType.tracksReps {
                if let w = prev.weight, let r = prev.reps {
                    Text("\(Int(w)) x \(r)")
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
            // Weighted bodyweight: +BW label, weight, x, reps
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("+BW")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 30)
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            // Standard weight + reps (barbell, dumbbell, kettlebell, machineOther)
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType == .repsOnly {
            // Reps only (bodyweight)
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("BW")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 60)
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        } else if equipmentType == .weightedDistance {
            // Weight + distance
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                NumericField(value: $workoutSet.distance, placeholder: "mi")
            }
        } else if equipmentType == .distance {
            // Distance only
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.distance, placeholder: "mi")
            }
        } else if equipmentType == .duration {
            // Duration only
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
            .frame(width: 50)
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
