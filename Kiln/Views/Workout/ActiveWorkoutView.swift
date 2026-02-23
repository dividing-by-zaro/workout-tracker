import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showEndConfirmation = false
    @State private var showExercisePicker = false
    @State private var swappingExercise: WorkoutExercise?

    var body: some View {
        if let workout = sessionManager.activeWorkout {
            VStack(spacing: 0) {
                if sessionManager.hasInterruptedWorkout {
                    interruptedBanner(workout: workout)
                }

                header(workout: workout)

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        RestTimerView(restTimer: sessionManager.restTimer)
                            .padding(.horizontal, DesignSystem.Spacing.md)

                        ForEach(workout.sortedExercises) { workoutExercise in
                            let preFill = buildPreFillData(for: workoutExercise)
                            ExerciseCardView(
                                workoutExercise: workoutExercise,
                                preFillData: preFill,
                                onCompleteSet: { workoutSet in
                                    sessionManager.completeSet(workoutSet, context: modelContext)
                                },
                                onSwapExercise: {
                                    swappingExercise = workoutExercise
                                },
                                onRemoveExercise: {
                                    removeExercise(workoutExercise)
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .grainedBackground()
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise, to: workout)
                }
            }
            .sheet(item: $swappingExercise) { workoutExercise in
                ExercisePickerView { newExercise in
                    swapExercise(workoutExercise, with: newExercise)
                }
            }
            .overlay {
                if showEndConfirmation {
                    endWorkoutOverlay
                }
            }
        }
    }

    private func header(workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(workout.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(sessionManager.formattedElapsedTime)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                showExercisePicker = true
            } label: {
                Image(systemName: DesignSystem.Icon.add)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.success)
                    .clipShape(Circle())
            }
            Button {
                showEndConfirmation = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                    Text("End")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .frame(height: 36)
                .padding(.horizontal, DesignSystem.Spacing.sm + 2)
                .background(DesignSystem.Colors.primary)
                .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
    }

    private var endWorkoutOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showEndConfirmation = false }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("End Workout")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Button {
                    showEndConfirmation = false
                    sessionManager.finishWorkout(context: modelContext)
                } label: {
                    Text("Finish")
                        .font(DesignSystem.Typography.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm + 2)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .background(DesignSystem.Colors.success)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }

                Button {
                    showEndConfirmation = false
                    sessionManager.discardWorkout(context: modelContext)
                } label: {
                    Text("Discard")
                        .font(DesignSystem.Typography.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm + 2)
                        .foregroundStyle(DesignSystem.Colors.destructive)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }

                Button {
                    showEndConfirmation = false
                } label: {
                    Text("Cancel")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background {
                ZStack {
                    DesignSystem.Colors.surface
                    CardGrainOverlay()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
            .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
    }

    private func addExercise(_ exercise: Exercise, to workout: Workout) {
        let order = workout.exercises.count
        let workoutExercise = WorkoutExercise(order: order, exercise: exercise, workout: workout)
        modelContext.insert(workoutExercise)

        let preFill = PreFillService.preFillSets(for: exercise, setCount: 3, in: modelContext)
        for (i, data) in preFill.enumerated() {
            let set = WorkoutSet(
                order: i,
                weight: data.weight,
                reps: data.reps,
                distance: data.distance,
                seconds: data.seconds,
                workoutExercise: workoutExercise
            )
            modelContext.insert(set)
        }
        try? modelContext.save()
    }

    private func interruptedBanner(workout: Workout) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("You have an unfinished workout")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            HStack(spacing: DesignSystem.Spacing.md) {
                Button("Resume") {
                    sessionManager.resumeInterruptedWorkout()
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)

                Button("Discard") {
                    sessionManager.discardInterruptedWorkout(context: modelContext)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.Colors.destructive)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
    }

    private func swapExercise(_ workoutExercise: WorkoutExercise, with newExercise: Exercise) {
        for set in workoutExercise.sets {
            modelContext.delete(set)
        }
        workoutExercise.exercise = newExercise

        let preFill = PreFillService.preFillSets(for: newExercise, setCount: 3, in: modelContext)
        for (i, data) in preFill.enumerated() {
            let set = WorkoutSet(
                order: i,
                weight: data.weight,
                reps: data.reps,
                distance: data.distance,
                seconds: data.seconds,
                workoutExercise: workoutExercise
            )
            modelContext.insert(set)
        }
        try? modelContext.save()
    }

    private func removeExercise(_ workoutExercise: WorkoutExercise) {
        modelContext.delete(workoutExercise)
        try? modelContext.save()
    }

    private func buildPreFillData(for workoutExercise: WorkoutExercise) -> [PreFillData] {
        guard let exercise = workoutExercise.exercise else { return [] }
        return PreFillService.preFillSets(for: exercise, setCount: workoutExercise.sets.count, in: modelContext)
    }
}
