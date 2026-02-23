import SwiftUI
import SwiftData

struct StartWorkoutView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @State private var showTemplateEditor = false
    @State private var editingTemplate: WorkoutTemplate?

    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Start Workout")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.md)

                Button {
                    sessionManager.startEmptyWorkout(context: modelContext)
                } label: {
                    HStack {
                        Image(systemName: DesignSystem.Icon.add)
                        Text("Start an Empty Workout")
                    }
                    .font(DesignSystem.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                HStack {
                    Text("Templates")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Button {
                        showTemplateEditor = true
                    } label: {
                        Image(systemName: DesignSystem.Icon.add)
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
                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                        ForEach(templates) { template in
                            TemplateCardView(template: template)
                                .onTapGesture {
                                    sessionManager.startWorkout(from: template, context: modelContext)
                                }
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
