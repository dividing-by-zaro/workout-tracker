import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Query(
        filter: #Predicate<Workout> { $0.isInProgress == false },
        sort: \Workout.startedAt,
        order: .reverse
    ) private var workouts: [Workout]
    @State private var editingWorkout: Workout?
    @State private var workoutToDelete: Workout?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("ALL SESSIONS")
                        .font(DesignSystem.Typography.eyebrow)
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                    Text("History")
                        .font(DesignSystem.Typography.h1Display)
                        .foregroundStyle(DesignSystem.Colors.ink)
                        .lineSpacing(0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 16)

                if workouts.isEmpty {
                    VStack(spacing: 6) {
                        Text("No bricks laid yet.")
                            .font(DesignSystem.Typography.italicBody)
                            .foregroundStyle(DesignSystem.Colors.ink3)
                        Text("Complete a workout to see it here.")
                            .font(DesignSystem.Typography.helper)
                            .foregroundStyle(DesignSystem.Colors.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
                } else {
                    LazyVStack(spacing: 12) {
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

                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
        .grainedBackground(DesignSystem.Colors.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
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
                    let localId = workout.id.uuidString
                    modelContext.delete(workout)
                    try? modelContext.save()
                    sessionManager.syncService?.markWorkoutDeleted(localId: localId)
                    Task { await sessionManager.syncService?.deleteWorkoutFromServer(localId: localId) }
                    workoutToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This cannot be undone.")
        }
    }
}
