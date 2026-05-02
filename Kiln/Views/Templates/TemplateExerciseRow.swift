import SwiftUI
import SwiftData

struct TemplateExerciseRow: View {
    @Bindable var templateExercise: TemplateExercise

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(DesignSystem.Colors.ink3)

            Text(templateExercise.exercise?.name ?? "Unknown")
                .font(DesignSystem.Typography.sans(14, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink)

            Spacer()

            Stepper(
                value: $templateExercise.defaultSets,
                in: 1...10
            ) {
                HStack(spacing: 0) {
                    Text("\(templateExercise.defaultSets)")
                        .font(DesignSystem.Typography.mono(13, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                        .monospacedDigit()
                    Text(" \u{00D7} sets")
                        .font(DesignSystem.Typography.sans(13, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                }
            }
            .fixedSize()
        }
        .padding(.vertical, 4)
    }
}
