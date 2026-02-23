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
                HStack {
                    Text("Workouts")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Button {
                        showTemplateEditor = true
                    } label: {
                        Image(systemName: DesignSystem.Icon.add)
                            .font(.title2)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                if templates.isEmpty {
                    Text("No templates yet. Create one or import from Strong.")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                } else {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(templates) { template in
                            TemplateCardView(
                                template: template,
                                averageDuration: WorkoutTemplate.averageDuration(
                                    for: template.name,
                                    from: completedWorkouts
                                ),
                                timesCompleted: WorkoutTemplate.workoutCount(
                                    for: template.name,
                                    from: completedWorkouts
                                ),
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
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .sheet(isPresented: $showTemplateEditor) {
            TemplateEditorView()
        }
        .sheet(item: $editingTemplate) { template in
            TemplateEditorView(existingTemplate: template)
        }
    }
}
