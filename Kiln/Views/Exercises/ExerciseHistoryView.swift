import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Query(filter: #Predicate<Workout> { !$0.isInProgress }) private var finishedWorkouts: [Workout]

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
    }

    // MARK: - Note header (inline, §3.2 pattern)

    private var noteHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.resolvedEquipmentType.displayName)
                .font(DesignSystem.Typography.helper12)
                .foregroundStyle(DesignSystem.Colors.ink3)

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
}
