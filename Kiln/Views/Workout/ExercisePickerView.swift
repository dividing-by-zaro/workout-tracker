import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showCreateExercise = false
    @State private var newExerciseName = ""
    @State private var newEquipmentType: EquipmentType = .barbell
    @State private var newBodyPart: BodyPart = .other

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
                            Text(exercise.resolvedEquipmentType.displayName)
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
            .sheet(isPresented: $showCreateExercise) {
                createExerciseSheet
            }
        }
    }

    private var createExerciseSheet: some View {
        NavigationStack {
            Form {
                Section("Exercise Name") {
                    TextField("Exercise name", text: $newExerciseName)
                }
                Section("Equipment Type") {
                    Picker("Equipment", selection: $newEquipmentType) {
                        ForEach(EquipmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Body Part") {
                    Picker("Body Part", selection: $newBodyPart) {
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Text(part.displayName).tag(part)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCreateExercise = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let exerciseType: ExerciseType = newEquipmentType.tracksWeight ? .strength :
                            (newEquipmentType == .repsOnly ? .bodyweight : .cardio)
                        let exercise = Exercise(
                            name: newExerciseName,
                            exerciseType: exerciseType,
                            bodyPart: newBodyPart,
                            equipmentType: newEquipmentType
                        )
                        modelContext.insert(exercise)
                        try? modelContext.save()
                        showCreateExercise = false
                        onSelect(exercise)
                        dismiss()
                    }
                    .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
