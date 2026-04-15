import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    let exercise: Exercise
    @Query private var workoutExercises: [WorkoutExercise]

    @Query(filter: #Predicate<Workout> { !$0.isInProgress }) private var finishedWorkouts: [Workout]

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    private var finishedSessions: [(workout: Workout, workoutExercise: WorkoutExercise)] {
        finishedWorkouts
            .compactMap { workout in
                guard let we = workout.exercises.first(where: { $0.exercise?.id == exercise.id }) else { return nil }
                let hasCompletedSets = we.sets.contains { $0.isCompleted }
                guard hasCompletedSets else { return nil }
                return (workout: workout, workoutExercise: we)
            }
            .sorted { $0.workout.startedAt > $1.workout.startedAt }
    }

    var body: some View {
        Group {
            if finishedSessions.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock",
                    description: Text("Complete a workout with this exercise to see your history.")
                )
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(finishedSessions, id: \.workoutExercise.id) { session in
                            sessionCard(session.workout, session.workoutExercise)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
                .grainedBackground()
            }
        }
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
