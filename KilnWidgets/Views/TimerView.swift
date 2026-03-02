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

            // Row 2: Set progress + next set preview
            HStack {
                Text(completedSetLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Color("WidgetTextSecondary"))
                    .layoutPriority(1)
                Spacer()
                Text(nextSetPreviewLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Color("WidgetTextSecondary"))
                    .lineLimit(1)
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

    private var nextSetPreviewLabel: String {
        let state = context.state
        // setNumber == 1 means the next set is from a new exercise
        let prefix = state.setNumber == 1 ? "Next: \(state.exerciseName) " : "Next: "
        let values: String
        switch state.equipmentCategory {
        case "weightReps":
            if let w = state.weight, let r = state.reps {
                values = "\(formatWeight(w)) lbs × \(r)"
            } else { values = "—" }
        case "repsOnly":
            if let r = state.reps {
                values = "× \(r)"
            } else { values = "—" }
        case "duration":
            if let s = state.duration {
                values = "\(Int(s))s"
            } else { values = "—" }
        case "distance":
            if let d = state.distance {
                values = String(format: "%.1f mi", d)
            } else { values = "—" }
        case "weightDistance":
            if let w = state.weight, let d = state.distance {
                values = "\(formatWeight(w)) lbs • \(String(format: "%.1f", d)) mi"
            } else { values = "—" }
        default:
            values = "—"
        }
        return prefix + values
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private var timerStart: Date {
        context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))
    }
}
