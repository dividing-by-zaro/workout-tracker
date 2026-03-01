import SwiftUI
import WidgetKit

struct CompleteView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundColor(Color("WidgetPrimary"))

            Text("All Sets Complete")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("WidgetTextPrimary"))

            HStack(spacing: 6) {
                Text(context.attributes.workoutName)
                    .font(.system(size: 14, weight: .medium))
                Text("•")
                    .font(.system(size: 14))
                Text(context.attributes.workoutStartedAt, style: .timer)
                    .font(.system(size: 14).monospacedDigit())
            }
            .foregroundColor(Color("WidgetTextSecondary"))

            Text("Tap to open app and finish")
                .font(.system(size: 11))
                .foregroundColor(Color("WidgetTextSecondary"))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .activityBackgroundTint(Color("WidgetBackground"))
        .activitySystemActionForegroundColor(Color("WidgetPrimary"))
    }
}
