import SwiftUI
import SwiftData

struct WorkoutCardView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Eyebrow: SESSION · MMM d
            HStack(spacing: 6) {
                Text("SESSION")
                    .font(DesignSystem.Typography.eyebrow)
                    .tracking(2)
                    .textCase(.uppercase)
                Text("·")
                    .font(DesignSystem.Typography.eyebrow)
                Text(workout.startedAt, format: .dateTime.month(.abbreviated).day())
                    .font(DesignSystem.Typography.eyebrow)
                    .tracking(2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(DesignSystem.Colors.ink3)

            // Title
            Text(workout.name)
                .font(DesignSystem.Typography.h2Display)
                .foregroundStyle(DesignSystem.Colors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Stats line: duration · volume lb
            HStack(spacing: 6) {
                Text(workout.formattedDuration)
                    .font(DesignSystem.Typography.mono(11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.ink2)

                if workout.totalVolume > 0 {
                    Text("·")
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink3)

                    Text(volumeString(workout.totalVolume))
                        .font(DesignSystem.Typography.mono(11, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.ink2)

                    Text("lb")
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
            }

            // Brick thumbnail row
            if !workout.exercises.isEmpty {
                let count = min(workout.exercises.count, 6)
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { _ in
                        BrickFill(cornerRadius: 4)
                            .frame(width: 24, height: 10)
                    }
                }
                .mortarShadow()
                .padding(.top, 6)
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
    }

    private func volumeString(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? String(Int(volume))
    }

    /// Retained for downstream consumers (other views may still reference if extended).
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
