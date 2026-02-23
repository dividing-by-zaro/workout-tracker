import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showFinishConfirmation = false
    @State private var showDiscardConfirmation = false
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

                addExerciseButton

                finishButton
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
            .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
                Button("Finish", role: .destructive) {
                    sessionManager.finishWorkout(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save this workout and return to templates?")
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
                if sessionManager.hasCompletedSets {
                    showDiscardConfirmation = true
                } else {
                    sessionManager.discardWorkout(context: modelContext)
                }
            } label: {
                Image(systemName: DesignSystem.Icon.close)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .alert("Discard Workout?", isPresented: $showDiscardConfirmation) {
                Button("Discard", role: .destructive) {
                    sessionManager.discardWorkout(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All progress will be lost.")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
    }

    private var finishButton: some View {
        Button {
            showFinishConfirmation = true
        } label: {
            Text("Finish Workout")
                .font(DesignSystem.Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.success)
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
    }

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            HStack {
                Image(systemName: DesignSystem.Icon.add)
                Text("Add Exercise")
            }
            .font(DesignSystem.Typography.body)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .foregroundStyle(DesignSystem.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
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
