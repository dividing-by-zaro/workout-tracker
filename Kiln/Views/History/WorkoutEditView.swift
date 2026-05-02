import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @State private var showExercisePicker = false
    @State private var swappingExercise: WorkoutExercise?
    @State private var preFillCache: [UUID: [PreFillData]] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    nameField

                    dateInfo

                    ForEach(workout.sortedExercises) { workoutExercise in
                        let preFill = preFillCache[workoutExercise.id] ?? []
                        ExerciseCardView(
                            workoutExercise: workoutExercise,
                            preFillData: preFill,
                            onCompleteSet: { workoutSet in
                                workoutSet.isCompleted.toggle()
                                workoutSet.completedAt = workoutSet.isCompleted ? .now : nil
                                try? modelContext.save()
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

                    Button {
                        showExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: DesignSystem.Icon.add)
                            Text("Add Exercise")
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.brick2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm + 2)
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
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .grainedBackground(DesignSystem.Colors.bg)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        try? modelContext.save()
                        sessionManager.syncService?.markWorkoutEdited(workout)
                        Task { await sessionManager.syncService?.updateWorkout(workout) }
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(DesignSystem.Typography.button)
                            .foregroundStyle(DesignSystem.Colors.brick2)
                    }
                }
            }
            .onAppear { refreshPreFillCache() }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                }
            }
            .sheet(item: $swappingExercise) { workoutExercise in
                ExercisePickerView { newExercise in
                    swapExercise(workoutExercise, with: newExercise)
                }
            }
        }
    }

    private var nameField: some View {
        TextField("Workout Name", text: $workout.name)
            .font(DesignSystem.Typography.h2Display)
            .foregroundStyle(DesignSystem.Colors.ink)
            .padding(DesignSystem.Spacing.md)
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
            .padding(.horizontal, DesignSystem.Spacing.md)
            .onChange(of: workout.name) {
                try? modelContext.save()
            }
    }

    private var dateInfo: some View {
        HStack(spacing: 10) {
            Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(DesignSystem.Typography.italicBody)
                .foregroundStyle(DesignSystem.Colors.ink3)

            Text("·")
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)

            Text(workout.formattedDuration)
                .font(DesignSystem.Typography.mono(13, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.ink2)

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private func addExercise(_ exercise: Exercise) {
        PreFillService.insertPrefilledExercise(exercise, into: workout, in: modelContext)
        try? modelContext.save()
        refreshPreFillCache()
    }

    private func swapExercise(_ workoutExercise: WorkoutExercise, with newExercise: Exercise) {
        PreFillService.replacePrefilledExercise(workoutExercise, with: newExercise, in: modelContext)
        try? modelContext.save()
        refreshPreFillCache()
    }

    private func removeExercise(_ workoutExercise: WorkoutExercise) {
        modelContext.delete(workoutExercise)
        for (i, ex) in workout.sortedExercises.enumerated() {
            ex.order = i
        }
        try? modelContext.save()
        refreshPreFillCache()
    }

    private func refreshPreFillCache() {
        let completedWorkouts = WorkoutHistoryService.fetchCompletedWorkouts(context: modelContext) ?? []
        var cache: [UUID: [PreFillData]] = [:]
        for ex in workout.sortedExercises {
            guard let exercise = ex.exercise else { continue }
            cache[ex.id] = PreFillService.preFillSets(
                for: exercise,
                setCount: ex.sets.count,
                in: completedWorkouts
            )
        }
        preFillCache = cache
    }
}
