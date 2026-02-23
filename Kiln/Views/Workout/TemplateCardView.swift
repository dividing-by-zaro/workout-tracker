import SwiftUI
import SwiftData

struct TemplateCardView: View {
    let template: WorkoutTemplate
    var averageDuration: String?
    var timesCompleted: Int = 0
    var onStart: (() -> Void)?

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .top) {
                Text(template.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                Spacer()

                if let onStart {
                    Button(action: onStart) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Start")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.sm + 2)
                        .padding(.vertical, DesignSystem.Spacing.xs + 2)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                    }
                }
            }

            metadataRow

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(template.sortedExercises.prefix(4)) { templateExercise in
                    if let exercise = templateExercise.exercise {
                        exerciseRow(templateExercise: templateExercise, exercise: exercise)
                    }
                }
                if template.exercises.count > 4 {
                    Text("+\(template.exercises.count - 4) more")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.leading, 24)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                DesignSystem.Colors.surface
                CardGrainOverlay()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            TemplateDetailSheet(
                template: template,
                averageDuration: averageDuration,
                timesCompleted: timesCompleted,
                onStart: onStart
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func exerciseRow(templateExercise: TemplateExercise, exercise: Exercise) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(exercise.resolvedBodyPart.iconAsset)
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 16, height: 16)
            Text("\(templateExercise.defaultSets) \u{00d7} \(exercise.name)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            metadataPill("\(template.exercises.count) exercises")
            if let avg = averageDuration {
                metadataPill(avg)
            }
            if let lastUsed = template.lastUsedAt {
                metadataPill(lastUsedLabel(lastUsed))
            }
        }
    }

    private func lastUsedLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 30 { return "\(days)d ago" }
        let months = days / 30
        return months == 1 ? "1mo ago" : "\(months)mo ago"
    }

    private func metadataPill(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(Capsule())
    }
}

// MARK: - Template Detail Sheet

private struct TemplateDetailSheet: View {
    let template: WorkoutTemplate
    var averageDuration: String?
    var timesCompleted: Int = 0
    var onStart: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text(template.name)
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        metadataPill("\(template.exercises.count) exercises")
                        if let avg = averageDuration {
                            metadataPill(avg)
                        }
                        if timesCompleted > 0 {
                            metadataPill("\(timesCompleted)x done")
                        }
                        if let lastUsed = template.lastUsedAt {
                            metadataPill(lastUsedLabel(lastUsed))
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ForEach(template.sortedExercises) { templateExercise in
                            if let exercise = templateExercise.exercise {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(exercise.resolvedBodyPart.iconAsset)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                        .frame(width: 20, height: 20)
                                    Text("\(templateExercise.defaultSets) \u{00d7} \(exercise.name)")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
                .padding(DesignSystem.Spacing.lg)
            }

            if let onStart {
                Button {
                    dismiss()
                    onStart()
                } label: {
                    Text("Start Workout")
                        .font(DesignSystem.Typography.body.bold())
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
        }
        .grainedBackground()
    }

    private func metadataPill(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(Capsule())
    }

    private func lastUsedLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 30 { return "\(days)d ago" }
        let months = days / 30
        return months == 1 ? "1mo ago" : "\(months)mo ago"
    }
}
