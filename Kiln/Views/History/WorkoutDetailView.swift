import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(workout.startedAt, format: .dateTime.weekday(.wide).month().day().year())
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(spacing: DesignSystem.Spacing.md) {
                        Label(workout.formattedDuration, systemImage: "clock")
                        Label(String(format: "%.0f lbs", workout.totalVolume), systemImage: "scalemass")
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                // Exercises
                ForEach(workout.sortedExercises) { workoutExercise in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text(workoutExercise.exercise?.name ?? "Exercise")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        ForEach(workoutExercise.sortedSets) { set in
                            HStack {
                                Text("Set \(set.order + 1)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .frame(width: 50, alignment: .leading)

                                Spacer()

                                DetailedSetLabelView(
                                    set: set,
                                    equipmentType: workoutExercise.exercise?.resolvedEquipmentType ?? .barbell,
                                    style: .workoutDetail
                                )
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                    .cardShadow()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .grainedBackground()
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
