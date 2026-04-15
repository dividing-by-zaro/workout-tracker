import Foundation
import SwiftData

@Model
final class ProfileChartConfig {
    var id: UUID
    var sortOrder: Int
    var exerciseId: UUID
    var exerciseName: String
    var metricRaw: String
    var rangeRaw: String
    var customStart: Date?
    var customEnd: Date?
    var createdAt: Date

    var metric: ChartMetric {
        get { ChartMetric(rawValue: metricRaw) ?? .totalVolume }
        set { metricRaw = newValue.rawValue }
    }

    var range: ChartRange {
        get { ChartRange(rawValue: rangeRaw) ?? .sixMonths }
        set { rangeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        sortOrder: Int = 0,
        exerciseId: UUID,
        exerciseName: String,
        metric: ChartMetric = .totalVolume,
        range: ChartRange = .sixMonths,
        customStart: Date? = nil,
        customEnd: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.metricRaw = metric.rawValue
        self.rangeRaw = range.rawValue
        self.customStart = customStart
        self.customEnd = customEnd
        self.createdAt = createdAt
    }
}
