import Foundation

struct ChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double
    var id: Date { date }
}

enum ChartDataService {
    /// Builds a time series for a given config from the provided completed workouts.
    /// Only workouts that contain the target exercise and fall inside the range
    /// contribute a point — no zero-filling.
    static func series(for config: ProfileChartConfig, workouts: [Workout], now: Date = .now) -> [ChartPoint] {
        guard let interval = config.range.dateInterval(
            now: now,
            customStart: config.customStart,
            customEnd: config.customEnd
        ) else { return [] }

        var points: [ChartPoint] = []
        for workout in workouts {
            guard let completedAt = workout.completedAt,
                  interval.contains(completedAt) else { continue }
            guard let match = workout.exercises.first(where: { $0.exercise?.id == config.exerciseId }) else {
                continue
            }
            guard let value = config.metric.value(for: match) else { continue }
            points.append(ChartPoint(date: completedAt, value: value))
        }
        return points.sorted { $0.date < $1.date }
    }
}
