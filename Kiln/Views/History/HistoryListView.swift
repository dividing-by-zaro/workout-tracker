import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(
        filter: #Predicate<Workout> { $0.isInProgress == false },
        sort: \Workout.startedAt,
        order: .reverse
    ) private var workouts: [Workout]

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
    }
}
