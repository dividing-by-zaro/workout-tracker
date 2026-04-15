import SwiftUI
import SwiftData

struct ChartConfigEditorView: View {
    enum Mode {
        case create
        case edit(ProfileChartConfig)
    }

    let mode: Mode
    let onSave: (_ exerciseId: UUID, _ exerciseName: String, _ metric: ChartMetric, _ range: ChartRange, _ customStart: Date?, _ customEnd: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var selectedExerciseId: UUID?
    @State private var selectedExerciseName: String = ""
    @State private var metric: ChartMetric = .totalVolume
    @State private var range: ChartRange = .sixMonths
    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
    @State private var customEnd: Date = .now
    @State private var searchText = ""
    @State private var showingExercisePicker = false

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var isValid: Bool {
        guard selectedExerciseId != nil else { return false }
        if range == .custom && customStart > customEnd { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        HStack {
                            Text(selectedExerciseName.isEmpty ? "Select exercise" : selectedExerciseName)
                                .foregroundStyle(selectedExerciseName.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.6))
                        }
                    }
                }

                Section("Metric") {
                    Picker("Metric", selection: $metric) {
                        ForEach(ChartMetric.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Range") {
                    Picker("Range", selection: $range) {
                        ForEach(ChartRange.allCases) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    if range == .custom {
                        DatePicker("Start", selection: $customStart, displayedComponents: .date)
                        DatePicker("End", selection: $customEnd, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Graph" : "New Graph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let id = selectedExerciseId else { return }
                        onSave(
                            id,
                            selectedExerciseName,
                            metric,
                            range,
                            range == .custom ? customStart : nil,
                            range == .custom ? customEnd : nil
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                exercisePickerSheet
            }
            .onAppear(perform: loadInitialState)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func loadInitialState() {
        if case .edit(let config) = mode {
            selectedExerciseId = config.exerciseId
            selectedExerciseName = config.exerciseName
            metric = config.metric
            range = config.range
            if let s = config.customStart { customStart = s }
            if let e = config.customEnd { customEnd = e }
        }
    }

    private var exercisePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        selectedExerciseId = exercise.id
                        selectedExerciseName = exercise.name
                        showingExercisePicker = false
                    } label: {
                        HStack {
                            Text(exercise.name)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Spacer()
                            if selectedExerciseId == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingExercisePicker = false }
                }
            }
        }
    }
}
