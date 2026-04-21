import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Query(filter: #Predicate<Workout> { !$0.isInProgress }) private var finishedWorkouts: [Workout]

    private var finishedSessions: [ExerciseHistorySession] {
        WorkoutHistoryService.exerciseSessions(for: exercise, in: finishedWorkouts)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                NotesSection(
                    title: "Exercise Note",
                    placeholder: "Add exercise note",
                    notes: $exercise.notes,
                    onSave: {
                        try? modelContext.save()
                        sessionManager.syncService?.syncExerciseMetadataChange(
                            for: exercise, in: modelContext
                        )
                    }
                )
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                .cardShadow()
                .padding(.horizontal, DesignSystem.Spacing.md)

                if finishedSessions.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "clock",
                        description: Text("Complete a workout with this exercise to see your history.")
                    )
                    .padding(.top, DesignSystem.Spacing.xl)
                } else {
                    ForEach(finishedSessions) { session in
                        sessionCard(session.workout, session.workoutExercise)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .grainedBackground()
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sessionCard(_ workout: Workout, _ workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(workout.startedAt, format: .dateTime.weekday(.wide).month().day().year())
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ForEach(workoutExercise.sortedSets.filter(\.isCompleted)) { set in
                HStack {
                    Text("Set \(set.order + 1)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .frame(width: 50, alignment: .leading)

                    Spacer()

                    DetailedSetLabelView(
                        set: set,
                        equipmentType: exercise.resolvedEquipmentType,
                        style: .exerciseHistory
                    )
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
