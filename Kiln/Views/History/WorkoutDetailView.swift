import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.startedAt, format: .dateTime.weekday(.wide).month().day().year())
                        .font(DesignSystem.Typography.italicBody)
                        .foregroundStyle(DesignSystem.Colors.ink3)

                    HStack(spacing: 6) {
                        Text(workout.formattedDuration)
                            .font(DesignSystem.Typography.mono(13, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.ink2)

                        if workout.totalVolume > 0 {
                            Text("·")
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.ink3)

                            Text(volumeString(workout.totalVolume))
                                .font(DesignSystem.Typography.mono(13, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.ink2)

                            Text("lb")
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.ink3)
                        }
                    }
                }
                .padding(.horizontal, 18)

                // Exercises
                ForEach(workout.sortedExercises) { workoutExercise in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(workoutExercise.exercise?.name ?? "Exercise")
                            .font(DesignSystem.Typography.h2Display)
                            .foregroundStyle(DesignSystem.Colors.ink)

                        ForEach(workoutExercise.sortedSets) { set in
                            HStack(alignment: .firstTextBaseline) {
                                Text(String(format: "%02d", set.order + 1))
                                    .font(DesignSystem.Typography.setIndex)
                                    .foregroundStyle(DesignSystem.Colors.ink)
                                    .frame(width: 28, alignment: .leading)

                                Spacer()

                                DetailedSetLabelView(
                                    set: set,
                                    equipmentType: workoutExercise.exercise?.resolvedEquipmentType ?? .barbell,
                                    style: .workoutDetail
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.card)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                    .cardShadow()
                    .padding(.horizontal, 14)
                }

                Color.clear.frame(height: 80)
            }
            .padding(.vertical, 16)
        }
        .grainedBackground(DesignSystem.Colors.bg)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func volumeString(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? String(Int(volume))
    }
}
