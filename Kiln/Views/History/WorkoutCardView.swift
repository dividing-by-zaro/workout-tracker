import SwiftUI
import SwiftData

struct WorkoutCardView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(workout.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(workout.startedAt, format: .dateTime.month().day().year())
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                Label(workout.formattedDuration, systemImage: "clock")
                Label(String(format: "%.0f lbs", workout.totalVolume), systemImage: "scalemass")
            }
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Exercise summary - show each exercise with best set
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(workout.sortedExercises.prefix(5)) { workoutExercise in
                    if let exercise = workoutExercise.exercise {
                        HStack {
                            Text(exercise.name)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text(bestSetLabel(for: workoutExercise))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                if workout.exercises.count > 5 {
                    Text("+\(workout.exercises.count - 5) more")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bestSetLabel(for workoutExercise: WorkoutExercise) -> String {
        guard let bestSet = workoutExercise.sortedSets.max(by: {
            ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0)
        }) else { return "" }

        if let w = bestSet.weight, let r = bestSet.reps {
            return "\(Int(w)) lb x \(r)"
        } else if let r = bestSet.reps {
            return "x \(r)"
        } else if let d = bestSet.distance, let s = bestSet.seconds {
            return String(format: "%.1f mi / %.0fs", d, s)
        }
        return ""
    }
}
