import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Yet",
                    systemImage: DesignSystem.Icon.exercises,
                    description: Text("Exercises will appear here once you complete a workout.")
                )
            } else if filteredExercises.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredExercises) { exercise in
                        NavigationLink {
                            ExerciseHistoryView(exercise: exercise)
                        } label: {
                            HStack {
                                Text(exercise.name)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Spacer()
                                Text(exercise.resolvedEquipmentType.displayName)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search exercises")
            }
        }
        .navigationTitle("Exercises")
    }
}
