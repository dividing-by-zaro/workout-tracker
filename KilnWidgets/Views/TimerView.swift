import SwiftUI
import WidgetKit
import AppIntents

struct TimerView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Exercise name + Skip button
            HStack {
                Text(context.state.exerciseName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("WidgetTextPrimary"))
                    .lineLimit(1)
                Spacer()
                Button(intent: SkipRestIntent()) {
                    Text("Skip")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color("WidgetDestructive"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("WidgetSurface").opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // Row 2: Inline set summaries
            HStack(spacing: 0) {
                setSummariesRow
                Spacer()
            }

            // Row 3: Large countdown timer
            Text(timerInterval: timerStart...context.state.restTimerEndDate, countsDown: true)
                .font(.system(size: 40, weight: .bold).monospacedDigit())
                .foregroundColor(Color("WidgetPrimary"))
                .frame(maxWidth: .infinity)

            // Row 4: Auto-updating progress bar
            ProgressView(
                timerInterval: timerStart...context.state.restTimerEndDate,
                countsDown: false
            )
            .tint(Color("WidgetPrimary"))


        }
        .padding(14)
        .activityBackgroundTint(Color("WidgetBackground"))
        .activitySystemActionForegroundColor(Color("WidgetPrimary"))
    }

    @ViewBuilder
    private var setSummariesRow: some View {
        let currentIndex = context.state.setNumber - 1
        HStack(spacing: 6) {
            ForEach(Array(context.state.setSummaries.enumerated()), id: \.offset) { index, summary in
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

    private var timerStart: Date {
        context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))
    }
}
