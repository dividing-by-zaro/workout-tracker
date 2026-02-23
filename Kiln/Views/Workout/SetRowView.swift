import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var workoutSet: WorkoutSet
    let setNumber: Int
    let exerciseType: ExerciseType
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
            switch exerciseType {
            case .strength:
                if let w = prev.weight, let r = prev.reps {
                    Text("\(Int(w)) x \(r)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    Text("—")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            case .cardio:
                if let d = prev.distance, let s = prev.seconds {
                    Text(String(format: "%.1f mi / %.0fs", d, s))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    Text("—")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            case .bodyweight:
                if let r = prev.reps {
                    Text("x \(r)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    Text("—")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        } else {
            Text("—")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var inputFields: some View {
        switch exerciseType {
        case .strength:
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.weight, placeholder: "lbs")
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                IntField(value: $workoutSet.reps, placeholder: "reps")
            }
        case .cardio:
            HStack(spacing: DesignSystem.Spacing.xs) {
                NumericField(value: $workoutSet.distance, placeholder: "mi")
                IntSeconds(value: $workoutSet.seconds, placeholder: "sec")
            }
        case .bodyweight:
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("BW")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 60)
                Text("x")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                IntField(value: $workoutSet.reps, placeholder: "reps")
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
