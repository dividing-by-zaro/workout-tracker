import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Query(sort: \Workout.startedAt, order: .reverse) private var allWorkouts: [Workout]
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query private var charts: [ProfileChartConfig]
    @State private var showingRename = false
    @State private var showingDeleteOptions = false
    @State private var showingMerge = false
    @State private var operationError: String?

    private var finishedWorkouts: [Workout] {
        allWorkouts.filter { !$0.isInProgress }
    }

    private var finishedSessions: [ExerciseHistorySession] {
        WorkoutHistoryService.exerciseSessions(for: exercise, in: finishedWorkouts)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                noteHeader

                if finishedSessions.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(finishedSessions) { session in
                            sessionCard(session.workout, session.workoutExercise)
                        }
                    }
                    .padding(.horizontal, 14)
                }

                Color.clear.frame(height: DesignSystem.Spacing.tabBarClearance)
            }
            .padding(.vertical, 16)
        }
        .brickWallBackground()
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingRename = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteOptions = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Exercise actions")
            }
        }
        .sheet(isPresented: $showingRename) {
            ExerciseRenameSheet(currentName: exercise.name) { newName in
                let result = try ExerciseManagementService.rename(
                    exercise,
                    to: newName,
                    allExercises: allExercises,
                    workouts: allWorkouts,
                    charts: charts,
                    context: modelContext
                )
                sessionManager.handleExerciseLibraryMutation(context: modelContext)
                sessionManager.syncService?.syncExerciseMutation(result)
            }
        }
        .sheet(isPresented: $showingMerge) {
            ExerciseMergeFlowView(source: exercise) {
                dismiss()
            }
        }
        .confirmationDialog(
            "Delete \(exercise.name) (\(exercise.resolvedEquipmentType.displayName))?",
            isPresented: $showingDeleteOptions,
            titleVisibility: .visible
        ) {
            if allExercises.count > 1 {
                Button("Merge into Another Exercise") {
                    showingMerge = true
                }
            }
            Button(deletionPreview.completedLogCount > 0 ? "Delete Exercise & Logs" : "Delete Exercise", role: .destructive) {
                deleteExercise()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deletionMessage)
        }
        .alert(
            "Exercise Could Not Be Changed",
            isPresented: Binding(
                get: { operationError != nil },
                set: { if !$0 { operationError = nil } }
            )
        ) {
            Button("OK") { operationError = nil }
        } message: {
            Text(operationError ?? "Unknown error")
        }
    }

    // MARK: - Note header (inline, §3.2 pattern)

    private var noteHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(exercise.resolvedEquipmentType.displayName)
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                Text("·")
                    .foregroundStyle(DesignSystem.Colors.ink3)
                Text("Logged \(finishedSessions.count) time\(finishedSessions.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .accessibilityLabel("Logged \(finishedSessions.count) time\(finishedSessions.count == 1 ? "" : "s")")
            }

            NotesSection(
                title: "Exercise Note",
                placeholder: "A note for this exercise\u{2026}",
                notes: $exercise.notes,
                onSave: {
                    try? modelContext.save()
                    sessionManager.syncService?.syncExerciseMetadataChange(
                        for: exercise, in: modelContext
                    )
                },
                style: .standalone
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No bricks laid for this exercise yet.")
                .font(DesignSystem.Typography.italicBody)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
            Text("Complete a workout with this exercise to see your history.")
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 48)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Session card

    private func sessionCard(_ workout: Workout, _ workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow(for: workout.startedAt))
                .font(DesignSystem.Typography.eyebrow)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(DesignSystem.Colors.ink3)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(workoutExercise.sortedSets.filter(\.isCompleted)) { set in
                    HStack(spacing: 10) {
                        Text(setIndexLabel(for: set.order))
                            .font(DesignSystem.Typography.setIndex)
                            .tracking(1.2)
                            .foregroundStyle(DesignSystem.Colors.ink)
                            .monospacedDigit()

                        DetailedSetLabelView(
                            set: set,
                            equipmentType: exercise.resolvedEquipmentType,
                            style: .exerciseHistory
                        )

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
    }

    // MARK: - Helpers

    private func eyebrow(for date: Date) -> String {
        let formatted = date.formatted(
            .dateTime.weekday(.abbreviated).month(.abbreviated).day()
        )
        return "SESSION \u{00B7} \(formatted)"
    }

    private func setIndexLabel(for order: Int) -> String {
        String(format: "%02d", order + 1)
    }

    // MARK: - Exercise management

    private var deletionPreview: ExerciseDeletionPreview {
        ExerciseManagementService.deletionPreview(
            for: exercise,
            workouts: allWorkouts,
            templates: templates,
            charts: charts
        )
    }

    private var deletionMessage: String {
        let impact = deletionPreview
        var parts: [String] = []
        if impact.completedLogCount > 0 {
            parts.append("\(impact.completedLogCount) logged workout\(impact.completedLogCount == 1 ? "" : "s")")
        }
        if impact.workoutEntryCount > 0 {
            parts.append("\(impact.workoutEntryCount) workout entr\(impact.workoutEntryCount == 1 ? "y" : "ies")")
        }
        if impact.setCount > 0 {
            parts.append("\(impact.setCount) set\(impact.setCount == 1 ? "" : "s")")
        }
        if impact.templateCount > 0 {
            parts.append("\(impact.templateCount) template entr\(impact.templateCount == 1 ? "y" : "ies")")
        }
        if impact.chartCount > 0 {
            parts.append("\(impact.chartCount) custom graph\(impact.chartCount == 1 ? "" : "s")")
        }

        if parts.isEmpty {
            return "This exercise is unused and will be permanently deleted."
        }
        return "Deleting without merging permanently removes " + parts.joined(separator: ", ") + ". Merge instead to preserve this data."
    }

    private func deleteExercise() {
        do {
            let result = try ExerciseManagementService.delete(
                exercise,
                workouts: allWorkouts,
                templates: templates,
                charts: charts,
                context: modelContext
            )
            sessionManager.handleExerciseLibraryMutation(context: modelContext)
            sessionManager.syncService?.syncExerciseMutation(result)
            dismiss()
        } catch {
            operationError = error.localizedDescription
        }
    }
}
