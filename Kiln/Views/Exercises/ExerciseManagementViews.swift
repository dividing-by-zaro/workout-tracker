import SwiftUI
import SwiftData

struct ExerciseRenameSheet: View {
    let currentName: String
    let onRename: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var errorMessage: String?

    init(currentName: String, onRename: @escaping (String) throws -> Void) {
        self.currentName = currentName
        self.onRename = onRename
        _name = State(initialValue: currentName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise name") {
                    TextField("Exercise name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(DesignSystem.Colors.brick2)
                    }
                }
            }
            .navigationTitle("Rename Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onRename(trimmedName)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(trimmedName.isEmpty || trimmedName == currentName)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ExerciseMergeFlowView: View {
    @Bindable var source: Exercise
    let onMerged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var workouts: [Workout]
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query private var charts: [ProfileChartConfig]

    @State private var searchText = ""
    @State private var selectedTarget: Exercise?
    @State private var preview: ExerciseMergePreview?
    @State private var errorMessage: String?
    @State private var isMerging = false

    private var candidates: [Exercise] {
        exercises.filter {
            $0.id != source.id &&
                (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let preview {
                    mergePreview(preview)
                } else {
                    targetPicker
                }
            }
            .navigationTitle(preview == nil ? "Merge Into" : "Merge Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if preview == nil {
                        Button("Cancel") { dismiss() }
                    } else {
                        Button {
                            self.preview = nil
                            selectedTarget = nil
                            errorMessage = nil
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(preview != nil && isMerging)
    }

    private var targetPicker: some View {
        List {
            Section {
                Text("Choose the exercise that should remain. Nothing changes until you review and confirm the full preview.")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }

            Section("Destination exercise") {
                if candidates.isEmpty {
                    Text(searchText.isEmpty ? "There are no other exercises to merge into." : "No exercises match your search.")
                        .foregroundStyle(DesignSystem.Colors.ink3)
                } else {
                    ForEach(candidates) { candidate in
                        Button {
                            selectedTarget = candidate
                            preview = ExerciseManagementService.makeMergePreview(
                                source: source,
                                target: candidate,
                                workouts: workouts,
                                templates: templates,
                                charts: charts
                            )
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(candidate.name)
                                        .foregroundStyle(DesignSystem.Colors.ink)
                                    Text(candidate.resolvedEquipmentType.displayName)
                                        .font(DesignSystem.Typography.helper)
                                        .foregroundStyle(DesignSystem.Colors.ink3)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(DesignSystem.Colors.ink3)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
    }

    private func mergePreview(_ preview: ExerciseMergePreview) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    previewSummary(preview)
                    metadataSection(preview)
                    workoutSection(preview)
                    templateSection(preview)
                    chartSection(preview)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DesignSystem.Typography.helper)
                            .foregroundStyle(DesignSystem.Colors.brick2)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(16)
            }
            .brickWallBackground()

            Button {
                executeMerge(preview)
            } label: {
                Text(isMerging ? "Merging…" : "Merge into \(preview.targetLabel)")
                    .font(DesignSystem.Typography.buttonLarge)
                    .foregroundStyle(DesignSystem.Colors.brickText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BrickButtonBackground(cornerRadius: DesignSystem.CornerRadius.button))
                    .mortarShadow()
            }
            .buttonStyle(.plain)
            .disabled(isMerging)
            .padding(16)
            .background(DesignSystem.Colors.bg)
        }
    }

    private func previewSummary(_ preview: ExerciseMergePreview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nothing has changed yet", systemImage: "eye")
                .font(DesignSystem.Typography.sans(14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)

            Text("\(preview.sourceLabel) will be removed. Its data will become part of \(preview.targetLabel).")
                .font(DesignSystem.Typography.sans(14, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink2)

            HStack(spacing: 10) {
                summaryStat("Source logs", preview.sourceLogCount)
                summaryStat("Target logs", preview.targetLogCount)
                summaryStat("After merge", preview.resultingLogCount)
            }

            if preview.overlappingLogCount > 0 {
                Text("\(preview.overlappingLogCount) workout\(preview.overlappingLogCount == 1 ? "" : "s") contain both exercises. Their sets will be combined into one exercise entry.")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
        }
        .previewCard()
    }

    private func summaryStat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(DesignSystem.Typography.sans(20, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.ink)
            Text(label)
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataSection(_ preview: ExerciseMergePreview) -> some View {
        previewSection("Metadata — exact result") {
            ForEach(preview.fields) { field in
                VStack(alignment: .leading, spacing: 7) {
                    Text(field.field)
                        .font(DesignSystem.Typography.sans(14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.ink)
                    previewValue("From source", field.sourceValue)
                    previewValue("From target", field.targetValue)
                    previewValue("Final value", field.resultValue, isResult: true)
                    Text(field.decision)
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
                .padding(.vertical, 7)

                if field.id != preview.fields.last?.id {
                    Divider().overlay(DesignSystem.Colors.hair)
                }
            }
        }
    }

    private func previewValue(_ label: String, _ value: String, isResult: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.eyebrow)
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.ink3)
            Text(value)
                .font(DesignSystem.Typography.sans(13, weight: isResult ? .semibold : .regular))
                .foregroundStyle(isResult ? DesignSystem.Colors.brick2 : DesignSystem.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func workoutSection(_ preview: ExerciseMergePreview) -> some View {
        previewSection("Workout entries reviewed — \(preview.workouts.count)") {
            if preview.workouts.isEmpty {
                emptyPreviewRow("No workout entries will change.")
            } else {
                ForEach(preview.workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(workout.name)
                                .font(DesignSystem.Typography.sans(14, weight: .semibold))
                            Spacer()
                            Text(workout.isInProgress ? "In progress" : workout.date.formatted(date: .abbreviated, time: .omitted))
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.ink3)
                        }
                        Text(workoutChangeDescription(workout, preview: preview))
                            .font(DesignSystem.Typography.helper)
                            .foregroundStyle(DesignSystem.Colors.ink2)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private func workoutChangeDescription(
        _ workout: ExerciseMergeWorkoutPreview,
        preview: ExerciseMergePreview
    ) -> String {
        if !workout.hasSourceEntry {
            return "Existing \(preview.targetLabel) entry stays; the merged metadata shown above applies."
        }
        if workout.combinesExistingEntries {
            return "Combine \(workout.sourceSetCount) source + \(workout.targetSetCount) target sets → \(workout.resultSetCount) sets"
        }
        return "Move \(workout.sourceSetCount) set\(workout.sourceSetCount == 1 ? "" : "s") to \(preview.targetLabel)"
    }

    private func templateSection(_ preview: ExerciseMergePreview) -> some View {
        previewSection("Templates — \(preview.templates.count)") {
            if preview.templates.isEmpty {
                emptyPreviewRow("No templates will change.")
            } else {
                ForEach(preview.templates) { template in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(template.name)
                            .font(DesignSystem.Typography.sans(14, weight: .semibold))
                        if let targetSets = template.targetDefaultSets {
                            Text("Both entries become one; default sets max(\(template.sourceDefaultSets), \(targetSets)) = \(template.resultDefaultSets)")
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.ink2)
                        } else {
                            Text("Exercise reference moves to \(preview.targetLabel) with \(template.sourceDefaultSets) default sets.")
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.ink2)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private func chartSection(_ preview: ExerciseMergePreview) -> some View {
        previewSection("Custom graphs — \(preview.charts.count)") {
            if preview.charts.isEmpty {
                emptyPreviewRow("No custom graphs will change.")
            } else {
                ForEach(preview.charts) { chart in
                    Text("\(chart.metricName) · \(chart.rangeName) → \(preview.targetLabel)")
                        .font(DesignSystem.Typography.sans(13, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    private func previewSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.eyebrow)
                .tracking(1.6)
                .foregroundStyle(DesignSystem.Colors.ink3)
            content()
        }
        .previewCard()
    }

    private func emptyPreviewRow(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.helper)
            .foregroundStyle(DesignSystem.Colors.ink3)
    }

    private func executeMerge(_ preview: ExerciseMergePreview) {
        guard let target = selectedTarget else { return }
        isMerging = true
        errorMessage = nil
        do {
            let result = try ExerciseManagementService.merge(
                source: source,
                into: target,
                preview: preview,
                workouts: workouts,
                templates: templates,
                charts: charts,
                context: modelContext
            )
            sessionManager.handleExerciseLibraryMutation(context: modelContext)
            sessionManager.syncService?.syncExerciseMutation(result)
            isMerging = false
            dismiss()
            onMerged()
        } catch ExerciseManagementError.previewOutOfDate(let refreshedPreview) {
            self.preview = refreshedPreview
            errorMessage = ExerciseManagementError.previewOutOfDate(refreshedPreview).localizedDescription
            isMerging = false
        } catch {
            errorMessage = error.localizedDescription
            isMerging = false
        }
    }
}

private extension View {
    func previewCard() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
    }
}
