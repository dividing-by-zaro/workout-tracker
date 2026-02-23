import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(\.modelContext) private var modelContext
    let preFillData: [PreFillData]
    var restTimer: RestTimerService? = nil
    var lastCompletedSetId: UUID? = nil
    var onCompleteSet: (WorkoutSet) -> Void
    var onDeleteSet: ((WorkoutSet) -> Void)?
    var onSwapExercise: (() -> Void)?
    var onRemoveExercise: (() -> Void)?

    private var equipmentType: EquipmentType {
        workoutExercise.exercise?.resolvedEquipmentType ?? .barbell
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

            columnHeaders

            ForEach(Array(workoutExercise.sortedSets.enumerated()), id: \.element.id) { index, workoutSet in
                let prefill = index < preFillData.count ? preFillData[index] : nil
                SwipeToDelete {
                    removeSet(workoutSet)
                } content: {
                    SetRowView(
                        workoutSet: workoutSet,
                        equipmentType: equipmentType,
                        previousData: prefill,
                        onComplete: { onCompleteSet(workoutSet) }
                    )
                }

                if let timer = restTimer, timer.isRunning, workoutSet.id == lastCompletedSetId {
                    RestTimerView(restTimer: timer)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .top))
                        ))
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
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: restTimer?.isRunning)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: lastCompletedSetId)
        .background {
            ZStack {
                DesignSystem.Colors.surface
                CardGrainOverlay()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
    }

    @ViewBuilder
    private var columnHeaders: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Color.clear.frame(width: 16)
            Text("PREVIOUS")
                .frame(maxWidth: .infinity, alignment: .center)
            if equipmentType.tracksWeight && equipmentType.tracksReps && equipmentType == .weightedBodyweight {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("").frame(width: 30)
                    Text("WEIGHT").frame(width: 60)
                    Text("").frame(width: 14)
                    Text("REPS").frame(width: 60)
                }
            } else if equipmentType.tracksWeight && equipmentType.tracksReps {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("WEIGHT").frame(width: 60)
                    Text("").frame(width: 14)
                    Text("REPS").frame(width: 60)
                }
            } else if equipmentType == .repsOnly {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("").frame(width: 60)
                    Text("").frame(width: 14)
                    Text("REPS").frame(width: 60)
                }
            } else if equipmentType == .weightedDistance {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("WEIGHT").frame(width: 60)
                    Text("DIST").frame(width: 60)
                }
            } else if equipmentType == .distance {
                Text("DIST").frame(width: 60)
            } else if equipmentType == .duration {
                Text("TIME").frame(width: 60)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
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
        if let onDeleteSet {
            onDeleteSet(workoutSet)
        } else {
            modelContext.delete(workoutSet)
            try? modelContext.save()
        }
    }
}
