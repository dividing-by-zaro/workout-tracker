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
                }

                Section("Exercises") {
                    if templateExercises.isEmpty {
                        Text("No exercises added yet")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                            for index in indexSet {
                                let te = templateExercises[index]
                                modelContext.delete(te)
                            }
                            templateExercises.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(existingTemplate == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        dismiss()
                    }
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
                    modelContext.insert(te)
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
        if let existing = existingTemplate {
            existing.name = name
            // Remove old exercises that were deleted
            for ex in existing.exercises where !templateExercises.contains(where: { $0.id == ex.id }) {
                modelContext.delete(ex)
            }
            // Update/add exercises
            for (index, te) in templateExercises.enumerated() {
                te.order = index
                te.template = existing
            }
        } else {
            let template = WorkoutTemplate(name: name)
            modelContext.insert(template)
            for (index, te) in templateExercises.enumerated() {
                te.order = index
                te.template = template
            }
        }
        try? modelContext.save()
    }
}
