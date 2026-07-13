import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var workoutSet: WorkoutSet
    let equipmentType: EquipmentType
    let previousData: PreFillData?
    var setIndex: Int = 1
    var brickOffset: CGFloat = 0
    var onComplete: () -> Void

    @Environment(WorkoutSessionManager.self) private var sessionManager

    var body: some View {
        Group {
            if workoutSet.isCompleted {
                brickRow
            } else {
                pendingRow
            }
        }
        .animation(.easeInOut(duration: 0.2), value: workoutSet.isCompleted)
    }

    // MARK: - Pending state

    private var pendingRow: some View {
        HStack(spacing: 10) {
            Text(indexLabel)
                .font(DesignSystem.Typography.setIndex)
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.ink)
                .frame(width: 14, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }

            previousLabelPending
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }

            inputFields
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.brick)
                .fill(DesignSystem.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.brick)
                .strokeBorder(
                    DesignSystem.Colors.hair,
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
        )
        .padding(.horizontal, DesignSystem.Spacing.brickInset)
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    // MARK: - Brick (completed) state

    private var brickRow: some View {
        HStack(spacing: 10) {
            Text(indexLabel)
                .font(DesignSystem.Typography.setIndex)
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.7))
                .frame(width: 14, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }

            previousLabelBrick
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }

            brickValueBlock
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BrickFill(cornerRadius: DesignSystem.CornerRadius.brick))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.brick))
        .mortarShadow()
        .brickStagger(offset: brickOffset)
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    private var indexLabel: String {
        String(format: "%02d", setIndex)
    }

    private func handleTap() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        onComplete()
    }

    // MARK: - Previous label (pending)

    @ViewBuilder
    private var previousLabelPending: some View {
        if let text = previousLabelText {
            Text(text)
                .font(DesignSystem.Typography.prevLine)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .lineLimit(1)
        } else {
            Text("—")
                .font(DesignSystem.Typography.prevLine)
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
    }

    @ViewBuilder
    private var previousLabelBrick: some View {
        if let text = previousLabelText {
            Text(text)
                .font(DesignSystem.Typography.prevLine)
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.7))
                .lineLimit(1)
        } else {
            Text("—")
                .font(DesignSystem.Typography.prevLine)
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.7))
        }
    }

    private var previousLabelText: String? {
        guard let prev = previousData else { return nil }
        if equipmentType.tracksWeight && equipmentType.tracksReps {
            if let w = prev.weight, let r = prev.reps {
                return "prev \(Int(w)) lb \u{00D7} \(r)"
            } else if let w = prev.weight {
                return "prev \(Int(w)) lb"
            }
            return nil
        } else if equipmentType.tracksReps && !equipmentType.tracksWeight {
            if let r = prev.reps {
                return "prev \u{00D7} \(r)"
            }
            return nil
        } else if equipmentType.tracksDistance {
            if let d = prev.distance {
                return String(format: "prev %.1f mi", d)
            }
            return nil
        } else if equipmentType.tracksDuration {
            if let s = prev.seconds {
                return String(format: "prev %.0fs", s)
            }
            return nil
        }
        return nil
    }

    // MARK: - Brick value block (right-side numerics on a completed brick)

    @ViewBuilder
    private var brickValueBlock: some View {
        let sync: () -> Void = { sessionManager.handleSetValueChange(for: workoutSet) }
        HStack(spacing: 10) {
            if equipmentType.tracksWeight && equipmentType.tracksReps {
                if equipmentType == .weightedBodyweight {
                    Text("+BW")
                        .font(DesignSystem.Typography.sans(10, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.5))
                }
                brickWeightInput(sync: sync)
                brickRepsInput(sync: sync)
            } else if equipmentType == .repsOnly {
                Text("BW")
                    .font(DesignSystem.Typography.sans(10, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.5))
                brickRepsInput(sync: sync)
            } else if equipmentType == .weightedDistance {
                brickWeightInput(sync: sync)
                brickDistanceInput(sync: sync)
            } else if equipmentType == .distance {
                brickDistanceInput(sync: sync)
            } else if equipmentType == .duration {
                brickDurationInput(sync: sync)
            }
        }
    }

    private func brickWeightInput(sync: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            NumericInputField(
                value: $workoutSet.weight,
                placeholder: "lb",
                incrementStep: 1.0,
                onValueChanged: sync,
                textColor: DesignSystem.Colors.brickText,
                showUnderline: false,
                width: 44,
                allowsNegative: true
            )
            Text("lb")
                .font(DesignSystem.Typography.sans(10, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.5))
        }
    }

    private func brickRepsInput(sync: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            Text("\u{00D7}")
                .font(DesignSystem.Typography.brickValue)
                .foregroundStyle(DesignSystem.Colors.brickText)
            IntInputField(
                value: $workoutSet.reps,
                placeholder: "reps",
                incrementStep: 1.0,
                onValueChanged: sync,
                textColor: DesignSystem.Colors.brickText,
                showUnderline: false,
                width: 36
            )
        }
    }

    private func brickDistanceInput(sync: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            NumericInputField(
                value: $workoutSet.distance,
                placeholder: "mi",
                incrementStep: 0.1,
                onValueChanged: sync,
                textColor: DesignSystem.Colors.brickText,
                showUnderline: false,
                width: 44
            )
            Text("mi")
                .font(DesignSystem.Typography.sans(10, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.5))
        }
    }

    private func brickDurationInput(sync: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            NumericInputField(
                value: $workoutSet.seconds,
                placeholder: "sec",
                incrementStep: 5.0,
                onValueChanged: sync,
                textColor: DesignSystem.Colors.brickText,
                showUnderline: false,
                width: 44
            )
            Text("s")
                .font(DesignSystem.Typography.sans(10, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.5))
        }
    }

    // MARK: - Input fields (pending)

    @ViewBuilder
    private var inputFields: some View {
        let sync: () -> Void = { sessionManager.handleSetValueChange(for: workoutSet) }
        if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
            HStack(spacing: 6) {
                Text("+BW")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 28)
                    .allowsHitTesting(false)
                NumericInputField(value: $workoutSet.weight, placeholder: "lb", incrementStep: 1.0, onValueChanged: sync, allowsNegative: true)
                Text("\u{00D7}")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntInputField(value: $workoutSet.reps, placeholder: "reps", incrementStep: 1.0, onValueChanged: sync)
            }
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            HStack(spacing: 6) {
                NumericInputField(value: $workoutSet.weight, placeholder: "lb", incrementStep: 1.0, onValueChanged: sync, allowsNegative: true)
                Text("\u{00D7}")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntInputField(value: $workoutSet.reps, placeholder: "reps", incrementStep: 1.0, onValueChanged: sync)
            }
        } else if equipmentType == .repsOnly {
            HStack(spacing: 6) {
                Text("BW")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 56)
                    .allowsHitTesting(false)
                Text("\u{00D7}")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 14)
                    .allowsHitTesting(false)
                IntInputField(value: $workoutSet.reps, placeholder: "reps", incrementStep: 1.0, onValueChanged: sync)
            }
        } else if equipmentType == .weightedDistance {
            HStack(spacing: 6) {
                NumericInputField(value: $workoutSet.weight, placeholder: "lb", incrementStep: 1.0, onValueChanged: sync, allowsNegative: true)
                NumericInputField(value: $workoutSet.distance, placeholder: "mi", incrementStep: 0.1, onValueChanged: sync)
            }
        } else if equipmentType == .distance {
            HStack(spacing: 6) {
                NumericInputField(value: $workoutSet.distance, placeholder: "mi", incrementStep: 0.1, onValueChanged: sync)
            }
        } else if equipmentType == .duration {
            HStack(spacing: 6) {
                NumericInputField(value: $workoutSet.seconds, placeholder: "sec", incrementStep: 5.0, onValueChanged: sync)
            }
        }
    }
}
