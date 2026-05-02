import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showEndConfirmation = false
    @State private var showExercisePicker = false
    @State private var swappingExercise: WorkoutExercise?
    @State private var showReorderSheet = false
    @State private var templateDiff: TemplateDiff?
    @State private var preFillCache: [UUID: [PreFillData]] = [:]
    @State private var sessionNumber: Int = 1

    var body: some View {
        if let workout = sessionManager.activeWorkout {
            VStack(spacing: 0) {
                header(workout: workout)

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.gapCard) {
                        ForEach(workout.sortedExercises) { workoutExercise in
                            let preFill = preFillCache[workoutExercise.id] ?? []
                            ExerciseCardView(
                                workoutExercise: workoutExercise,
                                preFillData: preFill,
                                restTimer: sessionManager.restTimer,
                                lastCompletedSetId: sessionManager.lastCompletedSetId,
                                onCompleteSet: { workoutSet in
                                    sessionManager.completeSet(workoutSet, context: modelContext)
                                },
                                onDeleteSet: { workoutSet in
                                    sessionManager.deleteSet(workoutSet, context: modelContext)
                                },
                                onSwapExercise: {
                                    swappingExercise = workoutExercise
                                },
                                onRemoveExercise: {
                                    removeExercise(workoutExercise)
                                },
                                onSkipRest: {
                                    sessionManager.skipRestTimer()
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.padCardOuter)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .brickWallBackground()
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise, to: workout)
                }
            }
            .sheet(item: $swappingExercise) { workoutExercise in
                ExercisePickerView { newExercise in
                    swapExercise(workoutExercise, with: newExercise)
                }
            }
            .sheet(isPresented: $showReorderSheet) {
                ExerciseReorderView(workout: workout)
            }
            .overlay {
                if showEndConfirmation {
                    endWorkoutOverlay
                }
            }
            .overlay(alignment: .top) {
                if sessionManager.showResumedToast {
                    Text("Workout resumed")
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink2)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.card)
                        .overlay(
                            Capsule().stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .cardShadow()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { sessionManager.showResumedToast = false }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: sessionManager.showResumedToast)
            .onAppear {
                refreshPreFillCache()
                refreshSessionNumber()
            }
            .onChange(of: workout.exercises.count) { refreshPreFillCache() }
        }
    }

    // MARK: - Header

    private func header(workout: Workout) -> some View {
        @Bindable var bindableWorkout = workout
        return VStack(alignment: .leading, spacing: 8) {
            // Eyebrow row
            HStack(alignment: .center) {
                Text(String(format: "SESSION NO. %d", sessionNumber))
                    .font(DesignSystem.Typography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                Spacer()
                firingPill
            }

            // Title row
            HStack(alignment: .center, spacing: 8) {
                Text(workout.name)
                    .font(DesignSystem.Typography.h1Display)
                    .tracking(-0.6)
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .lineSpacing(0)

                Spacer()

                Button {
                    showExercisePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink)
                        .frame(width: 34, height: 34)
                        .background(DesignSystem.Colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }

                Button {
                    showReorderSheet = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink)
                        .frame(width: 34, height: 34)
                        .background(DesignSystem.Colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }

                Button {
                    templateDiff = sessionManager.computeTemplateDiff(context: modelContext)
                    showEndConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                        Text("End")
                            .font(DesignSystem.Typography.button)
                            .foregroundStyle(DesignSystem.Colors.brickText)
                    }
                    .frame(height: 34)
                    .padding(.horizontal, 14)
                    .background(DesignSystem.Colors.red)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
            }

            NotesSection(
                title: "Workout Note",
                placeholder: "A note for today's session…",
                notes: $bindableWorkout.notes,
                onSave: { try? modelContext.save() },
                style: .standalone
            )
            .padding(.top, 10)
        }
        .padding(.horizontal, DesignSystem.Spacing.padPage)
        .padding(.vertical, 14)
    }

    private var firingPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignSystem.Colors.brick1)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.brick1.opacity(0.18), lineWidth: 3)
                )
            Text("FIRING")
                .font(DesignSystem.Typography.sectionLabel)
                .tracking(1.4)
                .foregroundStyle(DesignSystem.Colors.brick2)
            Rectangle()
                .fill(DesignSystem.Colors.brick2.opacity(0.3))
                .frame(width: 1, height: 9)
            Text(sessionManager.formattedElapsedTime)
                .font(DesignSystem.Typography.mono(11, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(DesignSystem.Colors.brick2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.brick1.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - End Workout overlay

    private var endWorkoutOverlay: some View {
        let diff = templateDiff

        return ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showEndConfirmation = false }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("End Workout")
                    .font(DesignSystem.Typography.h2Display)
                    .foregroundStyle(DesignSystem.Colors.ink)

                Button {
                    showEndConfirmation = false
                    sessionManager.finishWorkout(context: modelContext)
                } label: {
                    Text("Finish")
                        .font(DesignSystem.Typography.buttonLarge)
                        .foregroundStyle(DesignSystem.Colors.brickText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(BrickButtonBackground(cornerRadius: DesignSystem.CornerRadius.button))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                        .mortarShadow()
                }

                if let diff, diff.hasChanges {
                    Button {
                        showEndConfirmation = false
                        sessionManager.finishAndUpdateTemplate(context: modelContext)
                    } label: {
                        VStack(spacing: 2) {
                            Text("Finish & Update Template")
                                .font(DesignSystem.Typography.buttonLarge)
                                .foregroundStyle(DesignSystem.Colors.brickText)
                            Text(diff.description)
                                .font(DesignSystem.Typography.helper)
                                .foregroundStyle(DesignSystem.Colors.brickText.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            BrickFill(cornerRadius: DesignSystem.CornerRadius.button)
                                .opacity(0.85)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                        .mortarShadow()
                    }
                }

                Button {
                    showEndConfirmation = false
                    sessionManager.discardWorkout(context: modelContext)
                } label: {
                    Text("Discard")
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DesignSystem.Colors.bgDeeper)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }

                Button {
                    showEndConfirmation = false
                } label: {
                    Text("Cancel")
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.card)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
            .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Helpers

    private func addExercise(_ exercise: Exercise, to workout: Workout) {
        PreFillService.insertPrefilledExercise(exercise, into: workout, in: modelContext)
        try? modelContext.save()
        sessionManager.syncLiveActivityState()
        refreshPreFillCache()
    }

    private func swapExercise(_ workoutExercise: WorkoutExercise, with newExercise: Exercise) {
        PreFillService.replacePrefilledExercise(workoutExercise, with: newExercise, in: modelContext)
        try? modelContext.save()
        sessionManager.syncLiveActivityState()
        refreshPreFillCache()
    }

    private func removeExercise(_ workoutExercise: WorkoutExercise) {
        sessionManager.removeExercise(workoutExercise, context: modelContext)
    }

    private func refreshPreFillCache() {
        guard let workout = sessionManager.activeWorkout else { return }
        let completedWorkouts = WorkoutHistoryService.fetchCompletedWorkouts(context: modelContext) ?? []
        var cache: [UUID: [PreFillData]] = [:]
        for ex in workout.sortedExercises {
            guard let exercise = ex.exercise else { continue }
            cache[ex.id] = PreFillService.preFillSets(
                for: exercise,
                setCount: ex.sets.count,
                in: completedWorkouts
            )
        }
        preFillCache = cache
    }

    private func refreshSessionNumber() {
        let completed = WorkoutHistoryService.fetchCompletedWorkouts(context: modelContext)?.count ?? 0
        sessionNumber = completed + 1
    }
}
