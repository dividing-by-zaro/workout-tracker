import SwiftUI
import Charts
import SwiftData

struct CustomChartCard: View {
    @Bindable var config: ProfileChartConfig
    let workouts: [Workout]

    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var selectedDate: Date?

    private var points: [ChartPoint] {
        ChartDataService.series(for: config, workouts: workouts)
    }

    private var latestValue: Double? { points.last?.value }
    private var firstValue: Double? { points.first?.value }

    private var delta: Double? {
        guard let first = firstValue, let last = latestValue, first != 0 else { return nil }
        return last - first
    }

    private var deltaPercent: Double? {
        guard let first = firstValue, first != 0, let d = delta else { return nil }
        return (d / first) * 100
    }

    private var selectedPoint: ChartPoint? {
        guard let selectedDate else { return nil }
        return points.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
    }

    private var accentColor: Color { DesignSystem.Colors.chartLine }

    private var accentAreaGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(0.22), accentColor.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            header
            headlineValue
            chart
            footer
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .cardShadow()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(config.exerciseName)
                    .font(DesignSystem.Typography.sans(14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .lineLimit(1)
                Text(config.metric.displayName)
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
            Spacer()
            Menu {
                ForEach(ChartRange.allCases) { range in
                    Button {
                        config.range = range
                    } label: {
                        if config.range == range {
                            Label(range.displayName, systemImage: "checkmark")
                        } else {
                            Text(range.displayName)
                        }
                    }
                }
            } label: {
                rangeChip
            }

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
        }
    }

    private var rangeChip: some View {
        Text(config.range.displayName)
            .font(DesignSystem.Typography.helper12)
            .foregroundStyle(DesignSystem.Colors.ink2)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(DesignSystem.Colors.bgDeeper)
            )
    }

    // MARK: - Big value + delta

    private var headlineValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
            if let shown = selectedPoint?.value ?? latestValue {
                Text(Self.formatValue(shown))
                    .font(DesignSystem.Typography.mono(28, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .contentTransition(.numericText())
                Text(config.metric.shortUnit)
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            } else {
                Text("—")
                    .font(DesignSystem.Typography.mono(28, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
            Spacer()
            if let selected = selectedPoint {
                Text(selected.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(DesignSystem.Typography.mono(13, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.ink3)
            } else if let d = delta, let p = deltaPercent, points.count > 1 {
                deltaBadge(delta: d, percent: p)
            }
        }
    }

    private func deltaBadge(delta: Double, percent: Double) -> some View {
        let positive = delta >= 0
        let color = positive ? DesignSystem.Colors.brick1 : DesignSystem.Colors.red
        return HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(String(format: "%+.1f%%", percent))
                .font(DesignSystem.Typography.mono(13, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(color.opacity(0.10))
        )
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        if points.isEmpty {
            emptyChart
        } else {
            Chart {
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Date", p.date),
                        y: .value("Value", p.value)
                    )
                    .foregroundStyle(accentAreaGradient)
                    .interpolationMethod(.monotone)
                }

                ForEach(points) { p in
                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Value", p.value)
                    )
                    .foregroundStyle(accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }

                if points.count == 1, let only = points.first {
                    PointMark(
                        x: .value("Date", only.date),
                        y: .value("Value", only.value)
                    )
                    .foregroundStyle(accentColor)
                    .symbolSize(60)
                }

                if let selected = selectedPoint {
                    RuleMark(x: .value("Date", selected.date))
                        .foregroundStyle(DesignSystem.Colors.chartGrid)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.value)
                    )
                    .foregroundStyle(accentColor)
                    .symbolSize(90)
                }
            }
            .chartXScale(domain: xAxisDomain)
            .chartYScale(domain: .automatic(includesZero: config.metric == .totalVolume))
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                        .foregroundStyle(DesignSystem.Colors.chartGrid)
                    AxisValueLabel()
                        .font(DesignSystem.Typography.sans(10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: xAxisMonthStride)) { value in
                    AxisGridLine()
                        .foregroundStyle(DesignSystem.Colors.chartGrid)
                        .offset(y: 0)
                    AxisValueLabel(centered: false, anchor: .top) {
                        if let date = value.as(Date.self) {
                            Text(Self.monthYearLabel(date))
                                .font(DesignSystem.Typography.sans(10, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.ink3)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .onChange(of: selectedDate) { old, new in
                if old == nil, new != nil {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            .frame(height: 180)
        }
    }

    private var emptyChart: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(DesignSystem.Colors.bgDeeper.opacity(0.5))
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.ink3)
                Text("No data in range")
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
        }
        .frame(height: 180)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if points.isEmpty {
                Text(" ")
                    .font(DesignSystem.Typography.helper12)
            } else {
                Text("\(points.count) session\(points.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.helper12)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
            Spacer()
        }
    }

    // MARK: - Axis helpers

    private var xAxisDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        guard let first = points.first?.date, let last = points.last?.date else {
            let now = Date.now
            let start = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return start...now
        }
        let startComps = calendar.dateComponents([.year, .month], from: first)
        let start = calendar.date(from: startComps) ?? first
        let lastMonthStartComps = calendar.dateComponents([.year, .month], from: last)
        let lastMonthStart = calendar.date(from: lastMonthStartComps) ?? last
        let end = calendar.date(byAdding: .month, value: 1, to: lastMonthStart) ?? last
        return start...end
    }

    private var xAxisMonthStride: Int {
        let calendar = Calendar.current
        let domain = xAxisDomain
        let months = calendar.dateComponents([.month], from: domain.lowerBound, to: domain.upperBound).month ?? 6
        switch months {
        case ...3: return 1
        case 4...8: return 1
        case 9...14: return 2
        case 15...24: return 3
        default: return 6
        }
    }

    static func monthYearLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        let month = comps.month ?? 1
        if month == 1 {
            return String(comps.year ?? 2000)
        }
        return date.formatted(.dateTime.month(.abbreviated))
    }

    static func formatValue(_ value: Double) -> String {
        if value >= 10_000 {
            return String(format: "%.1fk", value / 1000)
        }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
