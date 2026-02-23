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

                                setDetailLabel(set: set, equipmentType: workoutExercise.exercise?.resolvedEquipmentType ?? .barbell)
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

    @ViewBuilder
    private func setDetailLabel(set: WorkoutSet, equipmentType: EquipmentType) -> some View {
        let bodyStyle = DesignSystem.Typography.body
        let captionStyle = DesignSystem.Typography.caption

        if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("+BW").font(bodyStyle).foregroundStyle(DesignSystem.Colors.textSecondary)
                if let w = set.weight { Text("\(Int(w)) lb").font(bodyStyle) }
                if let r = set.reps { Text("x \(r)").font(bodyStyle) }
                if let rpe = set.rpe { Text("RPE \(String(format: "%.0f", rpe))").font(captionStyle).foregroundStyle(DesignSystem.Colors.textSecondary) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        } else if equipmentType.tracksWeight && equipmentType.tracksReps {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight { Text("\(Int(w)) lb").font(bodyStyle) }
                if let r = set.reps { Text("x \(r)").font(bodyStyle) }
                if let rpe = set.rpe { Text("RPE \(String(format: "%.0f", rpe))").font(captionStyle).foregroundStyle(DesignSystem.Colors.textSecondary) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        } else if equipmentType == .repsOnly {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("BW").font(bodyStyle).foregroundStyle(DesignSystem.Colors.textSecondary)
                if let r = set.reps { Text("x \(r)").font(bodyStyle) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        } else if equipmentType == .weightedDistance {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let w = set.weight { Text("\(Int(w)) lb").font(bodyStyle) }
                if let d = set.distance { Text(String(format: "%.1f mi", d)).font(bodyStyle) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        } else if equipmentType == .distance {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let d = set.distance { Text(String(format: "%.1f mi", d)).font(bodyStyle) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        } else if equipmentType == .duration {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let s = set.seconds { Text(String(format: "%.0fs", s)).font(bodyStyle) }
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}
