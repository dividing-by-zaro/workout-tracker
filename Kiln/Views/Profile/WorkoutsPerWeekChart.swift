import SwiftUI
import Charts
import SwiftData

struct WorkoutsPerWeekChart: View {
    let workouts: [Workout]

    private var weeklyData: [(week: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date.now
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let currentWeekStart = currentWeekInterval.start
        var result: [(week: String, count: Int)] = []

        for weeksAgo in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: currentWeekStart),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { continue }

            let count = workouts.filter { workout in
                guard let completed = workout.completedAt else { return false }
                return completed >= weekStart && completed < weekEnd
            }.count

            let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
            result.append((week: label, count: count))
        }
        return result
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [DesignSystem.Colors.brick1, DesignSystem.Colors.brick2],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Workouts per week")
                .font(DesignSystem.Typography.sans(13, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)

            Chart(weeklyData, id: \.week) { item in
                BarMark(
                    x: .value("Week", item.week),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(barGradient)
                .cornerRadius(4)
            }
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
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(DesignSystem.Typography.sans(10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.ink3)
                }
            }
            .frame(height: 200)
        }
    }
}
