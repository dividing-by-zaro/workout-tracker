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

                                setDetailLabel(set: set, type: workoutExercise.exercise?.exerciseType ?? .strength)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func setDetailLabel(set: WorkoutSet, type: ExerciseType) -> some View {
        switch type {
        case .strength:
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight { Text("\(Int(w)) lb").font(DesignSystem.Typography.body) }
                if let r = set.reps { Text("x \(r)").font(DesignSystem.Typography.body) }
                if let rpe = set.rpe { Text("RPE \(String(format: "%.0f", rpe))").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        case .cardio:
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let d = set.distance { Text(String(format: "%.1f mi", d)).font(DesignSystem.Typography.body) }
                if let s = set.seconds { Text(String(format: "%.0fs", s)).font(DesignSystem.Typography.body) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        case .bodyweight:
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("BW").font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textSecondary)
                if let r = set.reps { Text("x \(r)").font(DesignSystem.Typography.body) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}
