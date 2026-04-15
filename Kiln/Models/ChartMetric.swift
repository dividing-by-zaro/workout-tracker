import Foundation

enum ChartMetric: String, CaseIterable, Identifiable {
    case totalVolume
    case estimatedOneRepMax

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .totalVolume: return "Total Volume"
        case .estimatedOneRepMax: return "Est. 1RM"
        }
    }

    var shortUnit: String { "lbs" }

    /// Computes the metric across all completed sets of a WorkoutExercise.
    /// Returns nil if no set contributes a value.
    func value(for workoutExercise: WorkoutExercise) -> Double? {
        let completed = workoutExercise.sets.filter(\.isCompleted)
        guard !completed.isEmpty else { return nil }

        switch self {
        case .totalVolume:
            let total = completed.reduce(0.0) { sum, set in
                sum + (set.weight ?? 0) * Double(set.reps ?? 0)
            }
            return total > 0 ? total : nil

        case .estimatedOneRepMax:
            var best: Double = 0
            for set in completed {
                guard let w = set.weight, w > 0, let r = set.reps, r > 0 else { continue }
                let e1rm = Self.oneRepMax(weight: w, reps: r)
                if e1rm > best { best = e1rm }
            }
            return best > 0 ? best : nil
        }
    }

    /// Epley for reps ≤ 12, O'Conner (more conservative) above that — Epley drifts
    /// optimistic at high reps, so switch to a flatter curve.
    static func oneRepMax(weight: Double, reps: Int) -> Double {
        if reps <= 1 { return weight }
        if reps <= 12 {
            return weight * (1.0 + Double(reps) / 30.0)
        }
        return weight * (1.0 + Double(reps) / 40.0)
    }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case threeMonths
    case sixMonths
    case oneYear
    case allTime
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .allTime: return "All"
        case .custom: return "Custom"
        }
    }

    func dateInterval(now: Date = .now, customStart: Date? = nil, customEnd: Date? = nil) -> DateInterval? {
        let calendar = Calendar.current
        switch self {
        case .threeMonths:
            guard let start = calendar.date(byAdding: .month, value: -3, to: now) else { return nil }
            return DateInterval(start: start, end: now)
        case .sixMonths:
            guard let start = calendar.date(byAdding: .month, value: -6, to: now) else { return nil }
            return DateInterval(start: start, end: now)
        case .oneYear:
            guard let start = calendar.date(byAdding: .year, value: -1, to: now) else { return nil }
            return DateInterval(start: start, end: now)
        case .allTime:
            return DateInterval(start: .distantPast, end: now)
        case .custom:
            guard let s = customStart, let e = customEnd, s <= e else { return nil }
            return DateInterval(start: s, end: e)
        }
    }
}
