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
                if workout.totalVolume > 0 {
                    Label(String(format: "%.0f lbs", workout.totalVolume), systemImage: "scalemass")
                }
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
        .background {
            ZStack {
                DesignSystem.Colors.surface
                CardGrainOverlay()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
    }

    private func bestSetLabel(for workoutExercise: WorkoutExercise) -> String {
        let completedSets = workoutExercise.sortedSets.filter(\.isCompleted)
        guard !completedSets.isEmpty else { return "" }
        let category = workoutExercise.exercise?.resolvedEquipmentType.equipmentCategory ?? "weightReps"

        switch category {
        case "weightReps", "weightDistance":
            guard let best = completedSets.max(by: {
                ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0)
            }) else { return "" }
            if let w = best.weight, let r = best.reps { return "\(Int(w)) lb x \(r)" }
            return ""
        case "repsOnly":
            guard let best = completedSets.max(by: { ($0.reps ?? 0) < ($1.reps ?? 0) }) else { return "" }
            if let r = best.reps { return "x \(r)" }
            return ""
        case "duration":
            guard let best = completedSets.max(by: { ($0.seconds ?? 0) < ($1.seconds ?? 0) }) else { return "" }
            if let s = best.seconds { return "\(Int(s))s" }
            return ""
        case "distance":
            guard let best = completedSets.max(by: { ($0.distance ?? 0) < ($1.distance ?? 0) }) else { return "" }
            if let d = best.distance { return String(format: "%.1f mi", d) }
            return ""
        default:
            return ""
        }
    }
}
