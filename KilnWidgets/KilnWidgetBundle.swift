import SwiftUI
import WidgetKit

@main
struct KilnWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen presentation
            Group {
                if context.state.isWorkoutComplete {
                    CompleteView(context: context)
                } else if context.state.isRestTimerActive {
                    TimerView(context: context)
                } else {
                    SetView(context: context)
                }
            }
            .widgetURL(URL(string: "kiln://active-workout"))
        } dynamicIsland: { context in
            // Required by API — minimal stubs (iPhone 13 has no Dynamic Island)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.exerciseName)
                        .font(.caption)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Set \(context.state.setNumber)")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isRestTimerActive {
                        Text(timerInterval: context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))...context.state.restTimerEndDate, countsDown: true)
                            .font(.caption)
                    }
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color("WidgetPrimary"))
            } compactTrailing: {
                if context.state.isRestTimerActive {
                    Text(timerInterval: context.state.restTimerEndDate.addingTimeInterval(-Double(context.state.restTotalSeconds))...context.state.restTimerEndDate, countsDown: true)
                        .font(.caption)
                        .frame(width: 40)
                } else {
                    Text("S\(context.state.setNumber)")
                        .font(.caption)
                }
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color("WidgetPrimary"))
            }
        }
    }
}
