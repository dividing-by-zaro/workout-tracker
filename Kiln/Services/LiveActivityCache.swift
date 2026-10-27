import Foundation

enum LiveActivityCache {
    private static let suite = UserDefaults(suiteName: "group.app.izaro.kiln")!

    private static let stateKey = "la.state"
    private static let setIdKey = "la.setId"
    private static let restDurationKey = "la.restDuration"
    private static let queueKey = "la.queue"
    private static let adjustedValuesKey = "la.adjustedValues"
    private static let completedSetIdsKey = "la.completedSetIds"
    private static let pushTokenKey = "la.pushToken"
    // Legacy single-set dirty markers (pre per-set adjustments)
    private static let legacyDirtyKey = "la.dirty"
    private static let legacyDirtySetIdKey = "la.dirtySetId"

    typealias ContentState = WorkoutActivityAttributes.ContentState

    /// One incomplete set, precomputed by the app so lock screen intents can
    /// advance through the workout without touching SwiftData (which forces FaceID).
    struct QueuedSet: Codable {
        var setId: UUID
        var workoutExerciseId: UUID
        var restDuration: Int
        var state: ContentState
    }

    /// Values the user adjusted on the lock screen for a specific set.
    struct AdjustedValues: Codable {
        var weight: Double?
        var reps: Int?
        var duration: Double?
        var distance: Double?
    }

    struct PendingSync {
        var completedSetIds: [UUID]
        var adjustedValues: [UUID: AdjustedValues]
    }

    // MARK: - Write full state from app

    /// Writes the displayed state plus the queue of remaining sets (current set first).
    /// Pending lock screen adjustments/completions are left alone — only
    /// `consumePendingSync()` clears them.
    static func cache(_ state: ContentState, queue: [QueuedSet]) {
        self.queue = queue
        writeState(state)
    }

    /// Lock screen completion: drops the completed set from the queue and shows `state`.
    static func advance(to state: ContentState) {
        var q = queue
        if !q.isEmpty { q.removeFirst() }
        queue = q
        writeState(state)
    }

    private static func writeState(_ state: ContentState) {
        self.state = state
        if let current = queue.first {
            suite.set(current.setId.uuidString, forKey: setIdKey)
            suite.set(current.restDuration, forKey: restDurationKey)
        } else {
            suite.removeObject(forKey: setIdKey)
            suite.set(0, forKey: restDurationKey)
        }
    }

    static func clearRest() {
        guard var s = state else { return }
        s.isRestTimerActive = false
        s.restTimerEndDate = .distantPast
        s.restTotalSeconds = 0
        state = s
    }

    // MARK: - Read cached state

    static var state: ContentState? {
        get {
            guard let data = suite.data(forKey: stateKey) else { return nil }
            return try? JSONDecoder().decode(ContentState.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: stateKey)
            } else {
                suite.removeObject(forKey: stateKey)
            }
        }
    }

    static var setId: UUID? {
        guard let str = suite.string(forKey: setIdKey) else { return nil }
        return UUID(uuidString: str)
    }

    static var restDuration: Int {
        suite.integer(forKey: restDurationKey)
    }

    static var queue: [QueuedSet] {
        get {
            guard let data = suite.data(forKey: queueKey) else { return [] }
            return (try? JSONDecoder().decode([QueuedSet].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: queueKey)
            }
        }
    }

    // MARK: - Push token persistence

    static var pushToken: String? {
        get { suite.string(forKey: pushTokenKey) }
        set {
            if let newValue {
                suite.set(newValue, forKey: pushTokenKey)
            } else {
                suite.removeObject(forKey: pushTokenKey)
            }
        }
    }

    // MARK: - Adjust weight/duration/distance

    static func adjustWeight(delta: Double) -> ContentState? {
        guard var s = state else { return nil }
        switch s.equipmentCategory {
        case "weightReps", "weightDistance":
            s.weight = (s.weight ?? 0) + delta
        case "duration":
            s.duration = max(0, (s.duration ?? 0) + delta)
        case "distance":
            s.distance = max(0, (s.distance ?? 0) + delta)
        default:
            return nil
        }
        updateCurrentSetSummary(&s)
        self.state = s
        recordAdjustment(from: s)
        return s
    }

    // MARK: - Adjust reps

    static func adjustReps(delta: Int) -> ContentState? {
        guard var s = state else { return nil }
        s.reps = max(0, (s.reps ?? 0) + delta)
        updateCurrentSetSummary(&s)
        self.state = s
        recordAdjustment(from: s)
        return s
    }

    private static func updateCurrentSetSummary(_ s: inout ContentState) {
        let idx = s.setNumber - 1
        guard idx >= 0 && idx < s.setSummaries.count else { return }
        s.setSummaries[idx].label = SetFormatter.summaryLabel(
            equipmentCategory: s.equipmentCategory,
            weight: s.weight,
            reps: s.reps,
            seconds: s.duration,
            distance: s.distance
        )
    }

    /// Snapshots the adjusted values keyed by the set being shown, so later
    /// completions and state rewrites can't clobber them or apply them to another set.
    private static func recordAdjustment(from s: ContentState) {
        guard let currentSetId = setId else { return }
        var values = adjustedValues
        values[currentSetId] = AdjustedValues(
            weight: s.weight,
            reps: s.reps,
            duration: s.duration,
            distance: s.distance
        )
        guard let data = try? JSONEncoder().encode(values) else { return }
        suite.set(data, forKey: adjustedValuesKey)
    }

    private static var adjustedValues: [UUID: AdjustedValues] {
        guard let data = suite.data(forKey: adjustedValuesKey) else { return [:] }
        return (try? JSONDecoder().decode([UUID: AdjustedValues].self, from: data)) ?? [:]
    }

    // MARK: - Record completion

    static func recordCompletion(setId: UUID) {
        var ids = suite.stringArray(forKey: completedSetIdsKey) ?? []
        ids.append(setId.uuidString)
        suite.set(ids, forKey: completedSetIdsKey)
    }

    // MARK: - Consume pending sync

    static func consumePendingSync() -> PendingSync? {
        let idStrings = suite.stringArray(forKey: completedSetIdsKey) ?? []
        let completedIds = idStrings.compactMap { UUID(uuidString: $0) }
        var adjusted = adjustedValues
        // Carry over an adjustment recorded by a build that predates per-set adjustments.
        if suite.bool(forKey: legacyDirtyKey),
           let legacyId = suite.string(forKey: legacyDirtySetIdKey).flatMap({ UUID(uuidString: $0) }),
           adjusted[legacyId] == nil,
           let s = state {
            adjusted[legacyId] = AdjustedValues(weight: s.weight, reps: s.reps, duration: s.duration, distance: s.distance)
        }

        guard !adjusted.isEmpty || !completedIds.isEmpty else { return nil }

        // Clear pending data
        suite.removeObject(forKey: adjustedValuesKey)
        suite.removeObject(forKey: completedSetIdsKey)
        suite.removeObject(forKey: legacyDirtyKey)
        suite.removeObject(forKey: legacyDirtySetIdKey)

        return PendingSync(completedSetIds: completedIds, adjustedValues: adjusted)
    }

    // MARK: - Clear all

    static func clear() {
        suite.removeObject(forKey: stateKey)
        suite.removeObject(forKey: setIdKey)
        suite.removeObject(forKey: restDurationKey)
        suite.removeObject(forKey: queueKey)
        suite.removeObject(forKey: adjustedValuesKey)
        suite.removeObject(forKey: completedSetIdsKey)
        suite.removeObject(forKey: pushTokenKey)
        suite.removeObject(forKey: legacyDirtyKey)
        suite.removeObject(forKey: legacyDirtySetIdKey)
    }
}
