import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
                        .font(DesignSystem.Typography.body.bold())
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm + 2)
                        .background {
                            ZStack {
                                DesignSystem.Colors.surface
                                CardGrainOverlay()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                        .cardShadow()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .grainedBackground()
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
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
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .padding(DesignSystem.Spacing.md)
            .background {
                ZStack {
                    DesignSystem.Colors.surface
                    CardGrainOverlay()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
            .padding(.horizontal, DesignSystem.Spacing.md)
            .onChange(of: workout.name) {
                try? modelContext.save()
            }
    }

    private var dateInfo: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Label(
                workout.startedAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )
            Label(
                workout.formattedDuration,
                systemImage: DesignSystem.Icon.timer
            )
            Spacer()
        }
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private func addExercise(_ exercise: Exercise) {
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
        refreshPreFillCache()
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
        var cache: [UUID: [PreFillData]] = [:]
        for ex in workout.sortedExercises {
            guard let exercise = ex.exercise else { continue }
            cache[ex.id] = PreFillService.preFillSets(for: exercise, setCount: ex.sets.count, in: modelContext)
        }
        preFillCache = cache
    }
}
