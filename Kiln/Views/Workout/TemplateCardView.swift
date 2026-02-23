import SwiftUI
import SwiftData

struct TemplateCardView: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(template.name)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(template.sortedExercises.prefix(4)) { templateExercise in
                    if let exercise = templateExercise.exercise {
                        Text("\(templateExercise.defaultSets) x \(exercise.name)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                if template.exercises.count > 4 {
                    Text("+\(template.exercises.count - 4) more")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            if let lastUsed = template.lastUsedAt {
                Text(lastUsed, format: .relative(presentation: .named))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
