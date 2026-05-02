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
    var onSkipRest: (() -> Void)? = nil

    private var equipmentType: EquipmentType {
        workoutExercise.exercise?.resolvedEquipmentType ?? .barbell
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.gapBrick) {
            headerRow
                .padding(.bottom, 2)

            if let exercise = workoutExercise.exercise {
                subtitleRow(for: exercise)
                    .padding(.bottom, 6)
            }

            setsStack
                .padding(.top, 2)

            Button {
                addSet()
            } label: {
                Text("+ Lay another brick")
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(DesignSystem.Colors.brick1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, DesignSystem.Spacing.padCardInner)
        .padding(.vertical, 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: restTimer?.isRunning)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: lastCompletedSetId)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text(workoutExercise.exercise?.name ?? "Exercise")
                .font(DesignSystem.Typography.h2Display)
                .tracking(-0.3)
                .foregroundStyle(DesignSystem.Colors.ink)

            Spacer()

            if let restSeconds = workoutExercise.exercise?.defaultRestSeconds {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink3)
                    Text("\(restSeconds) s")
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
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
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .padding(4)
            }
        }
    }

    // MARK: - Subtitle row (equipment + inline note)

    private func subtitleRow(for exercise: Exercise) -> some View {
        @Bindable var bindableExercise = exercise
        let hasNote = (exercise.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        return HStack(spacing: 6) {
            Text(exercise.resolvedEquipmentType.displayName)
                .font(DesignSystem.Typography.helper12)
                .foregroundStyle(DesignSystem.Colors.ink3)

            Text("·")
                .font(DesignSystem.Typography.helper12)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .opacity(hasNote ? 1 : 0.6)

            NotesSection(
                title: "Exercise Note",
                placeholder: "A note for this exercise…",
                notes: $bindableExercise.notes,
                onSave: {
                    try? modelContext.save()
                    WorkoutSessionManager.shared?.syncService?.syncExerciseMetadataChange(
                        for: exercise, in: modelContext
                    )
                },
                style: .inlineSuffix
            )

            Spacer(minLength: 0)
        }
    }

    // MARK: - Sets stack

    private var setsStack: some View {
        let sortedSets = workoutExercise.sortedSets
        // Precompute the brick stagger offset for each row using the
        // running-bond pattern indexed by completed-set position.
        var completedIdx = 0
        var offsets: [CGFloat] = []
        offsets.reserveCapacity(sortedSets.count)
        for s in sortedSets {
            if s.isCompleted {
                offsets.append(BrickStagger.offset(for: completedIdx))
                completedIdx += 1
            } else {
                offsets.append(0)
            }
        }

        return VStack(spacing: DesignSystem.Spacing.gapBrick) {
            ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, workoutSet in
                let prefill = index < preFillData.count ? preFillData[index] : nil
                let offset = index < offsets.count ? offsets[index] : 0

                SwipeToDelete {
                    removeSet(workoutSet)
                } content: {
                    SetRowView(
                        workoutSet: workoutSet,
                        equipmentType: equipmentType,
                        previousData: prefill,
                        setIndex: index + 1,
                        brickOffset: offset,
                        onComplete: { onCompleteSet(workoutSet) }
                    )
                }

                if let timer = restTimer, timer.isRunning, workoutSet.id == lastCompletedSetId {
                    RestTimerView(restTimer: timer, onSkip: onSkipRest)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .top))
                        ))
                }
            }
        }
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
