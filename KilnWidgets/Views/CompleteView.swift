import SwiftUI
import WidgetKit

struct CompleteView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Three small bricks instead of the flame icon.
            HStack(spacing: 4) {
                BrickFill(cornerRadius: 4).frame(width: 28, height: 14)
                BrickFill(cornerRadius: 4).frame(width: 28, height: 14)
                BrickFill(cornerRadius: 4).frame(width: 28, height: 14)
            }
            .mortarShadow()

            Text("All Sets Complete")
                .font(WidgetDesign.Typo.display(22))
                .foregroundColor(WidgetDesign.Color.textPrimary)

            HStack(spacing: 6) {
                Text(context.attributes.workoutName)
                    .font(WidgetDesign.Typo.sans(13, .medium))
                Text("·")
                    .font(WidgetDesign.Typo.sans(13))
                Text(context.attributes.workoutStartedAt, style: .timer)
                    .font(WidgetDesign.Typo.mono(13))
            }
            .foregroundColor(WidgetDesign.Color.textSecondary)

            Text("Tap to open app and finish")
                .font(WidgetDesign.Typo.sans(11))
                .italic()
                .foregroundColor(WidgetDesign.Color.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .activityBackgroundTint(WidgetDesign.Color.background)
        .activitySystemActionForegroundColor(WidgetDesign.Color.brick2)
    }
}
