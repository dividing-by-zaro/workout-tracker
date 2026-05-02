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
        ZStack {
            DesignSystem.Colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator

                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        exerciseSection
                        metricSection
                        rangeSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.padPage)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }

                saveButton
                    .padding(.horizontal, DesignSystem.Spacing.padPage)
                    .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            exercisePickerSheet
        }
        .onAppear(perform: loadInitialState)
    }

    // MARK: - Sections

    private var dragIndicator: some View {
        Capsule()
            .fill(DesignSystem.Colors.ink3.opacity(0.4))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(DesignSystem.Colors.ink2)
            }
            Spacer()
            Text(isEditing ? "Edit Graph" : "New Graph")
                .font(DesignSystem.Typography.h2Display)
                .foregroundStyle(DesignSystem.Colors.ink)
            Spacer()
            // Invisible placeholder to keep the title centered
            Text("Cancel")
                .font(DesignSystem.Typography.button)
                .opacity(0)
        }
        .padding(.horizontal, DesignSystem.Spacing.padPage)
        .padding(.top, DesignSystem.Spacing.sm)
        .padding(.bottom, DesignSystem.Spacing.md)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DesignSystem.Typography.helper)
            .tracking(1.4)
            .foregroundStyle(DesignSystem.Colors.ink3)
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Exercise")
            Button {
                showingExercisePicker = true
            } label: {
                HStack {
                    Text(selectedExerciseName.isEmpty ? "Select exercise" : selectedExerciseName)
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(selectedExerciseName.isEmpty ? DesignSystem.Colors.ink3 : DesignSystem.Colors.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(DesignSystem.Colors.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var metricSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Metric")
            Picker("Metric", selection: $metric) {
                ForEach(ChartMetric.allCases) { m in
                    Text(m.displayName).tag(m)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var rangeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            sectionHeader("Range")
            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { r in
                    Text(r.displayName).tag(r)
                }
            }
            .pickerStyle(.segmented)

            if range == .custom {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    DatePicker("Start", selection: $customStart, displayedComponents: .date)
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink)
                    DatePicker("End", selection: $customEnd, displayedComponents: .date)
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(DesignSystem.Colors.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                )
            }
        }
    }

    private var saveButton: some View {
        Button {
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
        } label: {
            Text("Save")
                .font(DesignSystem.Typography.buttonLarge)
                .foregroundStyle(DesignSystem.Colors.brickText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    BrickButtonBackground(cornerRadius: DesignSystem.CornerRadius.button)
                )
                .opacity(isValid ? 1 : 0.5)
                .mortarShadow()
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
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
                                .foregroundStyle(DesignSystem.Colors.ink)
                            Spacer()
                            if selectedExerciseId == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.brick1)
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
