import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(\.modelContext) private var modelContext
    let preFillData: [PreFillData]
    var onCompleteSet: (WorkoutSet) -> Void
    var onSwapExercise: (() -> Void)?
    var onRemoveExercise: (() -> Void)?

    private var exerciseType: ExerciseType {
        workoutExercise.exercise?.exerciseType ?? .strength
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(workoutExercise.exercise?.name ?? "Exercise")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                if let restSeconds = workoutExercise.exercise?.defaultRestSeconds {
                    Label("\(restSeconds)s", systemImage: DesignSystem.Icon.timer)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Menu {
                    Button { onSwapExercise?() } label: {
                        Label("Swap Exercise", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button(role: .destructive) { onRemoveExercise?() } label: {
                        Label("Remove Exercise", systemImage: DesignSystem.Icon.delete)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(DesignSystem.Spacing.xs)
                }
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("SET")
                    .frame(width: 28)
                Text("PREVIOUS")
                    .frame(width: 80, alignment: .leading)
                switch exerciseType {
                case .strength:
                    Text("LBS")
                    Text("")
                    Text("REPS")
                case .cardio:
                    Text("DIST")
                    Text("TIME")
                case .bodyweight:
                    Text("")
                    Text("")
                    Text("REPS")
                }
                Spacer()
                Text("")
            }
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            ForEach(Array(workoutExercise.sortedSets.enumerated()), id: \.element.id) { index, workoutSet in
                let prefill = index < preFillData.count ? preFillData[index] : nil
                SetRowView(
                    workoutSet: workoutSet,
                    setNumber: index + 1,
                    exerciseType: exerciseType,
                    previousData: prefill,
                    onComplete: { onCompleteSet(workoutSet) }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        removeSet(workoutSet)
                    } label: {
                        Label("Delete", systemImage: DesignSystem.Icon.delete)
                    }
                }
            }

            Button {
                addSet()
            } label: {
                HStack {
                    Image(systemName: DesignSystem.Icon.add)
                    Text("Add Set")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func addSet() {
        let existingSets = workoutExercise.sortedSets
        let newOrder = existingSets.count
        let lastSet = existingSets.last

        let newSet = WorkoutSet(
            order: newOrder,
            weight: lastSet?.weight,
            reps: lastSet?.reps,
            distance: lastSet?.distance,
            seconds: lastSet?.seconds,
            workoutExercise: workoutExercise
        )
        modelContext.insert(newSet)
        try? modelContext.save()
    }

    private func removeSet(_ workoutSet: WorkoutSet) {
        modelContext.delete(workoutSet)
        try? modelContext.save()
    }
}
