import SwiftUI

struct ExerciseReorderView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: Workout
    @State private var exercises: [WorkoutExercise]

    init(workout: Workout) {
        self.workout = workout
        self._exercises = State(initialValue: workout.sortedExercises)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text(exercise.exercise?.name ?? "Unknown")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("\(exercise.sets.count) sets")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                }
                .onMove { from, to in
                    exercises.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { offsets in
                    let toRemove = offsets.map { exercises[$0] }
                    exercises.remove(atOffsets: offsets)
                    for exercise in toRemove {
                        sessionManager.removeExercise(exercise, context: modelContext)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        sessionManager.reorderExercises(exercises, context: modelContext)
                        dismiss()
                    }
                }
            }
        }
    }
}
