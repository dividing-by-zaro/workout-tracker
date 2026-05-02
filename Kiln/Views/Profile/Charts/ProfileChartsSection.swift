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
            sectionHeader
                .padding(.horizontal, DesignSystem.Spacing.md)

            ForEach(configs) { config in
                CustomChartCard(
                    config: config,
                    workouts: workouts,
                    onEdit: { editingConfig = config },
                    onDelete: { delete(config) }
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
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

    private var sectionHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Text("Custom graphs")
                .font(DesignSystem.Typography.sans(13, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)
            Spacer()
            Button {
                showingCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(DesignSystem.Colors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func delete(_ config: ProfileChartConfig) {
        modelContext.delete(config)
        try? modelContext.save()
    }
}
