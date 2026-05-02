import SwiftUI
import SwiftData

struct TemplateCardView: View {
    let template: WorkoutTemplate
    var averageDuration: String?
    var timesCompleted: Int = 0
    var lastCompletedAt: Date?
    var onStart: (() -> Void)?

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .top) {
                Text(template.name)
                    .font(DesignSystem.Typography.h2Display)
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .lineLimit(2)

                Spacer()

                if let onStart {
                    Button(action: onStart) {
                        Text("Start")
                            .font(DesignSystem.Typography.button)
                            .foregroundStyle(DesignSystem.Colors.brickText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(BrickButtonBackground(cornerRadius: 8))
                            .mortarShadow()
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
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                        .padding(.leading, 24)
                }
            }
        }
        .padding(DesignSystem.Spacing.padCardInner)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
        }
        .cardShadow()
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            TemplateDetailSheet(
                template: template,
                averageDuration: averageDuration,
                timesCompleted: timesCompleted,
                lastCompletedAt: lastCompletedAt,
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
                .foregroundStyle(DesignSystem.Colors.ink3)
                .frame(width: 16, height: 16)
            Text("\(templateExercise.defaultSets) \u{00d7} \(exercise.name)")
                .font(DesignSystem.Typography.helper12)
                .foregroundStyle(DesignSystem.Colors.ink2)
                .lineLimit(1)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            TemplateMetadataPill("\(template.exercises.count) exercises")
            if let avg = averageDuration {
                TemplateMetadataPill(avg)
            }
            if let lastUsed = lastCompletedAt {
                TemplateMetadataPill(relativeUsageLabel(lastUsed))
            }
        }
    }
}

// MARK: - Template Detail Sheet

private struct TemplateDetailSheet: View {
    let template: WorkoutTemplate
    var averageDuration: String?
    var timesCompleted: Int = 0
    var lastCompletedAt: Date?
    var onStart: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text(template.name)
                        .font(DesignSystem.Typography.h1Display)
                        .foregroundStyle(DesignSystem.Colors.ink)

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        TemplateMetadataPill("\(template.exercises.count) exercises")
                        if let avg = averageDuration {
                            TemplateMetadataPill(avg)
                        }
                        if timesCompleted > 0 {
                            TemplateMetadataPill("\(timesCompleted)x done")
                        }
                        if let lastUsed = lastCompletedAt {
                            TemplateMetadataPill(relativeUsageLabel(lastUsed))
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ForEach(template.sortedExercises) { templateExercise in
                            if let exercise = templateExercise.exercise {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(exercise.resolvedBodyPart.iconAsset)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(DesignSystem.Colors.ink3)
                                        .frame(width: 20, height: 20)
                                    HStack(spacing: 6) {
                                        Text("\(templateExercise.defaultSets)")
                                            .font(DesignSystem.Typography.mono(13, weight: .semibold))
                                            .foregroundStyle(DesignSystem.Colors.ink)
                                        Text(exercise.name)
                                            .font(DesignSystem.Typography.body)
                                            .foregroundStyle(DesignSystem.Colors.ink)
                                    }
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
                    Text("Start")
                        .font(DesignSystem.Typography.buttonLarge)
                        .foregroundStyle(DesignSystem.Colors.brickText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BrickButtonBackground(cornerRadius: 8))
                        .mortarShadow()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
        }
        .brickWallBackground()
    }
}

private struct TemplateMetadataPill: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.helper)
            .foregroundStyle(DesignSystem.Colors.ink3)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(DesignSystem.Colors.bgDeeper)
            .clipShape(Capsule())
    }
}

private func relativeUsageLabel(_ date: Date) -> String {
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
