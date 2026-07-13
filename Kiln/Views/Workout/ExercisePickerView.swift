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

    private var trimmedNewExerciseName: String {
        newExerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private var duplicateNewExercise: Exercise? {
        let key = Exercise.identityKey(
            name: trimmedNewExerciseName,
            equipmentType: newEquipmentType
        )
        return exercises.first { $0.identityKey == key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if filteredExercises.isEmpty && !searchText.isEmpty {
                        Button {
                            newExerciseName = searchText
                            showCreateExercise = true
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(DesignSystem.Colors.ink2)
                                Text("Create \"\(searchText)\"")
                                    .font(DesignSystem.Typography.button)
                                    .foregroundStyle(DesignSystem.Colors.brick1)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .background(DesignSystem.Colors.hair)
                    }

                    ForEach(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Text(exercise.name)
                                    .font(DesignSystem.Typography.sans(14, weight: .regular))
                                    .foregroundStyle(DesignSystem.Colors.ink)
                                Spacer()
                                Text(exercise.resolvedEquipmentType.displayName)
                                    .font(DesignSystem.Typography.helper)
                                    .foregroundStyle(DesignSystem.Colors.ink3)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .background(DesignSystem.Colors.hair)
                    }
                }
            }
            .background(
                DesignSystem.Colors.bg.ignoresSafeArea()
            )
            .brickWallBackground()
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.ink2)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateExercise = true
                        newExerciseName = ""
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DesignSystem.Colors.ink)
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
                if let duplicateNewExercise {
                    Section {
                        Text("\(duplicateNewExercise.name) (\(duplicateNewExercise.resolvedEquipmentType.displayName)) already exists.")
                            .foregroundStyle(DesignSystem.Colors.brick2)
                    }
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
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !trimmedNewExerciseName.isEmpty, duplicateNewExercise == nil else { return }
                        let exerciseType: ExerciseType = newEquipmentType.tracksWeight ? .strength :
                            (newEquipmentType == .repsOnly ? .bodyweight : .cardio)
                        let exercise = Exercise(
                            name: trimmedNewExerciseName,
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
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(DesignSystem.Colors.brick2)
                    .disabled(trimmedNewExerciseName.isEmpty || duplicateNewExercise != nil)
                }
            }
        }
    }
}
