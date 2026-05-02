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
            VStack(spacing: 0) {
                Capsule()
                    .fill(DesignSystem.Colors.ink3.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                List {
                    ForEach(exercises) { exercise in
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Text(exercise.exercise?.name ?? "Unknown")
                                    .font(DesignSystem.Typography.sans(14, weight: .regular))
                                    .foregroundStyle(DesignSystem.Colors.ink)
                                Text("\(exercise.sets.count) sets")
                                    .font(DesignSystem.Typography.helper)
                                    .foregroundStyle(DesignSystem.Colors.ink3)
                            }
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(DesignSystem.Colors.ink3)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .listRowBackground(DesignSystem.Colors.card)
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
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .background(DesignSystem.Colors.bg.ignoresSafeArea())
            .navigationTitle("Reorder Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        sessionManager.reorderExercises(exercises, context: modelContext)
                        dismiss()
                    }
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(DesignSystem.Colors.brick2)
                }
            }
        }
    }
}
