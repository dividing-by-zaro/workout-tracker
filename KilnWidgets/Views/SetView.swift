import SwiftUI
import WidgetKit
import AppIntents

struct SetView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Exercise name + Complete button
            HStack {
                Text(context.state.exerciseName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("WidgetTextPrimary"))
                    .lineLimit(1)
                Spacer()
                Button(intent: CompleteSetIntent()) {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13))
                        Text("Done")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color("WidgetPrimary"))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Row 2: Inline set summaries
            HStack(spacing: 0) {
                setSummariesRow
                Spacer()
            }

            // Row 4: Input fields with +/- buttons
            inputFieldsRow
        }
        .padding(14)
        .activityBackgroundTint(Color("WidgetBackground"))
        .activitySystemActionForegroundColor(Color("WidgetPrimary"))
    }

    @ViewBuilder
    private var setSummariesRow: some View {
        let currentIndex = context.state.setNumber - 1
        HStack(spacing: 0) {
            ForEach(Array(context.state.setSummaries.enumerated()), id: \.offset) { index, summary in
                if index > 0 {
                    Spacer(minLength: 6)
                }
                if summary.isCompleted {
                    HStack(spacing: 2) {
                        Image("brick_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text(summary.label)
                            .font(.system(size: 16).monospacedDigit())
                    }
                    .foregroundColor(Color("WidgetTextSecondary").opacity(0.6))
                } else if index == currentIndex {
                    Text(summary.label)
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundColor(Color("WidgetPrimary"))
                } else {
                    Text(summary.label)
                        .font(.system(size: 16).monospacedDigit())
                        .foregroundColor(Color("WidgetTextSecondary"))
                }
            }
        }
    }

    @ViewBuilder
    private var inputFieldsRow: some View {
        let category = context.state.equipmentCategory
        HStack(spacing: 8) {
            if category == "weightReps" || category == "weightDistance" {
                adjustableField(
                    label: "WEIGHT",
                    value: formatWeight(context.state.weight),
                    unit: "lbs",
                    decrementIntent: AdjustWeightIntent(delta: -1),
                    incrementIntent: AdjustWeightIntent(delta: 1)
                )
            }

            if category == "weightReps" || category == "repsOnly" {
                adjustableField(
                    label: "REPS",
                    value: "\(context.state.reps ?? 0)",
                    unit: nil,
                    decrementIntent: AdjustRepsIntent(delta: -1),
                    incrementIntent: AdjustRepsIntent(delta: 1)
                )
            }

            if category == "duration" {
                adjustableField(
                    label: "SECONDS",
                    value: "\(Int(context.state.duration ?? 0))",
                    unit: "s",
                    decrementIntent: AdjustWeightIntent(delta: -5),
                    incrementIntent: AdjustWeightIntent(delta: 5)
                )
            }

            if category == "distance" || category == "weightDistance" {
                adjustableField(
                    label: "DISTANCE",
                    value: String(format: "%.1f", context.state.distance ?? 0),
                    unit: "mi",
                    decrementIntent: AdjustWeightIntent(delta: -0.1),
                    incrementIntent: AdjustWeightIntent(delta: 0.1)
                )
            }
        }
    }

    private func adjustableField<D: AppIntent, I: AppIntent>(
        label: String,
        value: String,
        unit: String?,
        decrementIntent: D,
        incrementIntent: I
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color("WidgetTextSecondary"))

            HStack(spacing: 4) {
                Button(intent: decrementIntent) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("WidgetTextSecondary"))
                }
                .buttonStyle(.plain)

                HStack(spacing: 1) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundColor(Color("WidgetTextPrimary"))
                    if let unit {
                        Text(unit)
                            .font(.system(size: 10))
                            .foregroundColor(Color("WidgetTextSecondary"))
                    }
                }

                Button(intent: incrementIntent) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("WidgetPrimary"))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatWeight(_ value: Double?) -> String {
        guard let value else { return "0" }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
