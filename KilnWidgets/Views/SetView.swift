import SwiftUI
import WidgetKit
import AppIntents

struct SetView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Exercise name + Done brick
            HStack(alignment: .firstTextBaseline) {
                Text(context.state.exerciseName)
                    .font(WidgetDesign.Typo.display(22))
                    .foregroundColor(WidgetDesign.Color.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(intent: CompleteSetIntent()) {
                    Text("Done")
                        .font(WidgetDesign.Typo.sans(13, .bold))
                        .foregroundColor(WidgetDesign.Color.brickText)
                        .frame(width: 72, height: 32)
                        .background(BrickFill(cornerRadius: 4))
                        .mortarShadow()
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 14)

            // Row 2: Inline set summaries (wraps when too wide)
            setSummariesRow
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 14)

            // Row 3: Stepper bins
            inputFieldsRow
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .activityBackgroundTint(WidgetDesign.Color.background)
        .activitySystemActionForegroundColor(WidgetDesign.Color.brick2)
    }

    @ViewBuilder
    private var setSummariesRow: some View {
        let currentIndex = context.state.setNumber - 1
        SetSummariesFlow(horizontalSpacing: 10, verticalSpacing: 4) {
            ForEach(Array(context.state.setSummaries.enumerated()), id: \.offset) { index, summary in
                if index == currentIndex {
                    Text(summary.label)
                        .font(WidgetDesign.Typo.mono(12, .bold))
                        .foregroundColor(WidgetDesign.Color.brick2)
                        .lineLimit(1)
                } else if summary.isCompleted {
                    Text(summary.label)
                        .font(WidgetDesign.Typo.mono(11))
                        .foregroundColor(WidgetDesign.Color.textSecondary.opacity(0.55))
                        .lineLimit(1)
                } else {
                    Text(summary.label)
                        .font(WidgetDesign.Typo.mono(11))
                        .foregroundColor(WidgetDesign.Color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var inputFieldsRow: some View {
        let category = context.state.equipmentCategory
        HStack(spacing: 8) {
            if category == "weightReps" || category == "weightDistance" || category == "weightedBodyweight" {
                stepperBin(
                    label: "WEIGHT",
                    value: (context.state.weight ?? 0).formattedWeight,
                    unit: "lbs",
                    decrementIntent: AdjustWeightIntent(delta: -1),
                    incrementIntent: AdjustWeightIntent(delta: 1)
                )
            }

            if category == "weightReps" || category == "repsOnly" || category == "weightedBodyweight" {
                stepperBin(
                    label: "REPS",
                    value: "\(context.state.reps ?? 0)",
                    unit: nil,
                    decrementIntent: AdjustRepsIntent(delta: -1),
                    incrementIntent: AdjustRepsIntent(delta: 1)
                )
            }

            if category == "duration" {
                stepperBin(
                    label: "SECONDS",
                    value: "\(Int(context.state.duration ?? 0))",
                    unit: "s",
                    decrementIntent: AdjustWeightIntent(delta: -5),
                    incrementIntent: AdjustWeightIntent(delta: 5)
                )
            }

            if category == "distance" || category == "weightDistance" {
                stepperBin(
                    label: "DISTANCE",
                    value: String(format: "%.1f", context.state.distance ?? 0),
                    unit: "mi",
                    decrementIntent: AdjustWeightIntent(delta: -0.1),
                    incrementIntent: AdjustWeightIntent(delta: 0.1)
                )
            }
        }
    }

    /// Cream "stepper bin" with a hair stroke. Minus/plus buttons are
    /// neutral circles — red is reserved for destructive actions per §9.2.
    private func stepperBin<D: AppIntent, I: AppIntent>(
        label: String,
        value: String,
        unit: String?,
        decrementIntent: D,
        incrementIntent: I
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(WidgetDesign.Typo.sans(8, .bold))
                .tracking(1.2)
                .foregroundColor(WidgetDesign.Color.textSecondary)

            HStack(spacing: 6) {
                stepperButton(systemName: "minus", intent: decrementIntent)

                HStack(spacing: 2) {
                    Text(value)
                        .font(WidgetDesign.Typo.mono(16, .bold))
                        .foregroundColor(WidgetDesign.Color.textPrimary)
                    if let unit {
                        Text(unit)
                            .font(WidgetDesign.Typo.sans(9, .semibold))
                            .foregroundColor(WidgetDesign.Color.textSecondary)
                    }
                }

                stepperButton(systemName: "plus", intent: incrementIntent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(WidgetDesign.Color.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(WidgetDesign.Color.hair, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func stepperButton<I: AppIntent>(systemName: String, intent: I) -> some View {
        Button(intent: intent) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(WidgetDesign.Color.textSecondary)
                .frame(width: 22, height: 22)
                .background(Color.white)
                .overlay(Circle().strokeBorder(WidgetDesign.Color.hair, lineWidth: 1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
