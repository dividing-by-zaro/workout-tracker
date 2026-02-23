import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showCreateExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseType: ExerciseType = .strength

    var onSelect: (Exercise) -> Void

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredExercises.isEmpty && !searchText.isEmpty {
                    Button {
                        newExerciseName = searchText
                        showCreateExercise = true
                    } label: {
                        Label("Create \"\(searchText)\"", systemImage: DesignSystem.Icon.add)
                    }
                }

                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            Text(exercise.name)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Text(exercise.exerciseType.rawValue.capitalized)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateExercise = true
                        newExerciseName = ""
                    } label: {
                        Image(systemName: DesignSystem.Icon.add)
                    }
                }
            }
            .alert("New Exercise", isPresented: $showCreateExercise) {
                TextField("Exercise name", text: $newExerciseName)
                Picker("Type", selection: $newExerciseType) {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                Button("Create") {
                    let exercise = Exercise(name: newExerciseName, exerciseType: newExerciseType)
                    modelContext.insert(exercise)
                    try? modelContext.save()
                    onSelect(exercise)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
