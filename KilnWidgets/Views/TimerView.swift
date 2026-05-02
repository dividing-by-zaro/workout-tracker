import SwiftUI
import WidgetKit
import AppIntents

struct TimerView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Exercise name + Skip text
            HStack(alignment: .firstTextBaseline) {
                Text(context.state.exerciseName)
                    .font(WidgetDesign.Typo.display(22))
                    .foregroundColor(WidgetDesign.Color.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(intent: SkipRestIntent()) {
                    Text("Skip")
                        .font(WidgetDesign.Typo.sans(13, .bold))
                        .foregroundColor(WidgetDesign.Color.brick2)
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 14)

            // Row 2: Set summaries — current set highlighted in brick2.
            setSummariesRow
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 8)

            // Row 3: Large countdown numerals (ink).
            Text(timerInterval: timerStart...context.state.restTimerEndDate, countsDown: true)
                .font(WidgetDesign.Typo.mono(38, .bold))
                .foregroundColor(WidgetDesign.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 6)

            // Row 4: Auto-updating progress bar tinted brick1. SwiftUI has
            // no first-class "timer-driven width" primitive in a widget,
            // so we use the system `ProgressView(timerInterval:)` and tint
            // it. The native bar already has rounded ends.
            ProgressView(
                timerInterval: timerStart...context.state.restTimerEndDate,
                countsDown: false
            )
            .tint(WidgetDesign.Color.brick1)
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

    private var timerStart: Date {
        context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))
    }
}
