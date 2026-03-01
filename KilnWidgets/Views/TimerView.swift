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

            // Row 2: REST label + set progress
            HStack {
                Text("REST")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color("WidgetTextSecondary"))
                    .tracking(2)
                Text(completedSetLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Color("WidgetTextSecondary"))
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

    private var completedSetLabel: String {
        let completed = context.state.setNumber - 1
        if completed > 0 {
            return "Set \(completed) of \(context.state.totalSetsInExercise) complete"
        }
        return "All sets complete"
    }

    private var timerStart: Date {
        context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))
    }
}
