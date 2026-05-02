import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingTemplate: WorkoutTemplate?

    @State private var name: String = ""
    @State private var templateExercises: [TemplateExercise] = []
    @State private var showExercisePicker = false

    init(existingTemplate: WorkoutTemplate? = nil) {
        self.existingTemplate = existingTemplate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("e.g. Push Day", text: $name)
                        .font(DesignSystem.Typography.sans(15, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink)
                }

                Section("Exercises") {
                    if templateExercises.isEmpty {
                        Text("No exercises added yet")
                            .font(DesignSystem.Typography.italicBody)
                            .foregroundStyle(DesignSystem.Colors.ink3)
                    } else {
                        ForEach(templateExercises) { te in
                            TemplateExerciseRow(templateExercise: te)
                        }
                        .onMove { from, to in
                            templateExercises.move(fromOffsets: from, toOffset: to)
                            for (index, te) in templateExercises.enumerated() {
                                te.order = index
                            }
                        }
                        .onDelete { indexSet in
                            templateExercises.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                            .font(DesignSystem.Typography.button)
                            .foregroundStyle(DesignSystem.Colors.brick2)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.bg)
            .navigationTitle(existingTemplate == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        dismiss()
                    }
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(DesignSystem.Colors.brick2)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    let te = TemplateExercise(
                        order: templateExercises.count,
                        defaultSets: 3,
                        exercise: exercise
                    )
                    templateExercises.append(te)
                }
            }
            .onAppear {
                if let existing = existingTemplate {
                    name = existing.name
                    templateExercises = existing.sortedExercises
                }
            }
        }
    }

    private func saveTemplate() {
        let template: WorkoutTemplate
        if let existing = existingTemplate {
            existing.name = name
            template = existing
            // Remove old exercises that were deleted from the local list
            for ex in existing.exercises where !templateExercises.contains(where: { $0.id == ex.id }) {
                modelContext.delete(ex)
            }
        } else {
            template = WorkoutTemplate(name: name)
            modelContext.insert(template)
        }

        for (index, te) in templateExercises.enumerated() {
            te.order = index
            te.template = template
            if te.modelContext == nil {
                modelContext.insert(te)
            }
        }

        try? modelContext.save()
    }
}
