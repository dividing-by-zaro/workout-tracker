import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Workout> { $0.isInProgress == false },
        sort: \Workout.startedAt,
        order: .reverse
    ) private var workouts: [Workout]
    @State private var editingWorkout: Workout?
    @State private var workoutToDelete: Workout?

    var body: some View {
        ScrollView {
            if workouts.isEmpty {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text("No workouts yet")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text("Complete a workout to see it here")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.xxl)
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(workouts) { workout in
                        NavigationLink(value: workout) {
                            WorkoutCardView(workout: workout)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                editingWorkout = workout
                            } label: {
                                Label("Edit", systemImage: DesignSystem.Icon.edit)
                            }
                            Button(role: .destructive) {
                                workoutToDelete = workout
                            } label: {
                                Label("Delete", systemImage: DesignSystem.Icon.delete)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .grainedBackground()
        .navigationTitle("History")
        .navigationDestination(for: Workout.self) { workout in
            WorkoutDetailView(workout: workout)
        }
        .sheet(item: $editingWorkout) { workout in
            WorkoutEditView(workout: workout)
        }
        .alert(
            "Delete Workout",
            isPresented: Binding(
                get: { workoutToDelete != nil },
                set: { if !$0 { workoutToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    modelContext.delete(workout)
                    try? modelContext.save()
                    workoutToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This cannot be undone.")
        }
    }
}
