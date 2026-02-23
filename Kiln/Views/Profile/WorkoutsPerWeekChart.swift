import SwiftUI
import Charts
import SwiftData

struct WorkoutsPerWeekChart: View {
    let workouts: [Workout]

    private var weeklyData: [(week: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date.now
        var result: [(week: String, count: Int)] = []

        for weeksAgo in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now) else { continue }
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!

            let count = workouts.filter { workout in
                guard let completed = workout.completedAt else { return false }
                return completed >= weekStart && completed < weekEnd
            }.count

            let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
            result.append((week: label, count: count))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Workouts Per Week")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Chart(weeklyData, id: \.week) { item in
                BarMark(
                    x: .value("Week", item.week),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(DesignSystem.Colors.primary)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(DesignSystem.Typography.caption)
                }
            }
            .frame(height: 200)
        }
    }
}
