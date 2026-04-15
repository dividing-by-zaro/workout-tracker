import SwiftUI
import SwiftData

struct ProfileChartsSection: View {
    let workouts: [Workout]

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProfileChartConfig.sortOrder) private var configs: [ProfileChartConfig]

    @State private var editingConfig: ProfileChartConfig?
    @State private var showingCreate = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ForEach(configs) { config in
                CustomChartCard(
                    config: config,
                    workouts: workouts,
                    onEdit: { editingConfig = config },
                    onDelete: { delete(config) }
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
            }

            addButton
                .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .sheet(isPresented: $showingCreate) {
            ChartConfigEditorView(mode: .create) { exerciseId, exerciseName, metric, range, customStart, customEnd in
                let config = ProfileChartConfig(
                    sortOrder: (configs.map(\.sortOrder).max() ?? -1) + 1,
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    metric: metric,
                    range: range,
                    customStart: customStart,
                    customEnd: customEnd
                )
                modelContext.insert(config)
                try? modelContext.save()
            }
        }
        .sheet(item: $editingConfig) { config in
            ChartConfigEditorView(mode: .edit(config)) { exerciseId, exerciseName, metric, range, customStart, customEnd in
                config.exerciseId = exerciseId
                config.exerciseName = exerciseName
                config.metric = metric
                config.range = range
                config.customStart = customStart
                config.customEnd = customEnd
                try? modelContext.save()
            }
        }
    }

    private var addButton: some View {
        Button {
            showingCreate = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.primary)
                Text("Add Graph")
                    .font(DesignSystem.Typography.label)
                    .foregroundStyle(DesignSystem.Colors.primary)
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.surface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .strokeBorder(
                        DesignSystem.Colors.primary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func delete(_ config: ProfileChartConfig) {
        modelContext.delete(config)
        try? modelContext.save()
    }
}
