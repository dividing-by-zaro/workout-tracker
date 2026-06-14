import SwiftUI
import SwiftData

struct StartWorkoutView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query(filter: #Predicate<Workout> { !$0.isInProgress }) private var completedWorkouts: [Workout]
    @State private var showTemplateEditor = false
    @State private var editingTemplate: WorkoutTemplate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack(alignment: .center) {
                    Text("Workouts")
                        .font(DesignSystem.Typography.h1Display)
                        .foregroundStyle(DesignSystem.Colors.ink)

                    Spacer()

                    Button {
                        showTemplateEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DesignSystem.Colors.ink)
                            .frame(width: 34, height: 34)
                            .background(DesignSystem.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                            }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.padPage)

                if templates.isEmpty {
                    Text("No templates yet. Lay your first one.")
                        .font(DesignSystem.Typography.italicBody)
                        .foregroundStyle(DesignSystem.Colors.ink3)
                        .padding(.horizontal, DesignSystem.Spacing.padCardOuter)
                } else {
                    LazyVStack(spacing: DesignSystem.Spacing.gapCard) {
                        ForEach(templates) { template in
                            let historySummary = WorkoutHistoryService.templateSummary(
                                for: template.name,
                                in: completedWorkouts
                            )
                            let lastCompletedAt = completedWorkouts
                                .filter { $0.templateId == template.id }
                                .compactMap(\.completedAt)
                                .max()
                            TemplateCardView(
                                template: template,
                                averageDuration: historySummary.averageDuration,
                                timesCompleted: historySummary.workoutCount,
                                lastCompletedAt: lastCompletedAt,
                                onStart: {
                                    sessionManager.startWorkout(from: template, context: modelContext)
                                }
                            )
                            .contextMenu {
                                Button {
                                    editingTemplate = template
                                } label: {
                                    Label("Edit", systemImage: DesignSystem.Icon.edit)
                                }
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: DesignSystem.Icon.delete)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.padCardOuter)
                }

                Color.clear.frame(height: DesignSystem.Spacing.tabBarClearance)
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .brickWallBackground()
        .sheet(isPresented: $showTemplateEditor) {
            TemplateEditorView()
        }
        .sheet(item: $editingTemplate) { template in
            TemplateEditorView(existingTemplate: template)
        }
    }
}
