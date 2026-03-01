import Foundation

enum LiveActivityCache {
    private static let suite = UserDefaults(suiteName: "group.app.izaro.kiln")!

    private static let stateKey = "la.state"
    private static let setIdKey = "la.setId"
    private static let restDurationKey = "la.restDuration"
    private static let dirtyKey = "la.dirty"
    private static let completedSetIdsKey = "la.completedSetIds"

    typealias ContentState = WorkoutActivityAttributes.ContentState

    struct PendingSync {
        var completedSetIds: [UUID]
        var isDirty: Bool
        var currentState: ContentState?
    }

    // MARK: - Write full state from app

    static func cache(_ state: ContentState, setId: UUID?, restDuration: Int) {
        if let data = try? JSONEncoder().encode(state) {
            suite.set(data, forKey: stateKey)
        }
        if let setId {
            suite.set(setId.uuidString, forKey: setIdKey)
        }
        suite.set(restDuration, forKey: restDurationKey)
        suite.set(false, forKey: dirtyKey)
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

    // MARK: - Adjust weight/duration/distance

    static func adjustWeight(delta: Double) -> ContentState? {
        guard var s = state else { return nil }
        switch s.equipmentCategory {
        case "weightReps", "weightDistance":
            s.weight = max(0, (s.weight ?? 0) + delta)
        case "duration":
            s.duration = max(0, (s.duration ?? 0) + delta)
        case "distance":
            s.distance = max(0, (s.distance ?? 0) + delta)
        default:
            return nil
        }
        self.state = s
        suite.set(true, forKey: dirtyKey)
        return s
    }

    // MARK: - Adjust reps

    static func adjustReps(delta: Int) -> ContentState? {
        guard var s = state else { return nil }
        s.reps = max(0, (s.reps ?? 0) + delta)
        self.state = s
        suite.set(true, forKey: dirtyKey)
        return s
    }

    // MARK: - Record completion

    static func recordCompletion(setId: UUID) {
        var ids = suite.stringArray(forKey: completedSetIdsKey) ?? []
        ids.append(setId.uuidString)
        suite.set(ids, forKey: completedSetIdsKey)
    }

    /// Read-only access to pending completion IDs (without consuming them)
    static var pendingCompletionIds: Set<UUID> {
        let idStrings = suite.stringArray(forKey: completedSetIdsKey) ?? []
        return Set(idStrings.compactMap { UUID(uuidString: $0) })
    }

    // MARK: - Consume pending sync

    static func consumePendingSync() -> PendingSync? {
        let isDirty = suite.bool(forKey: dirtyKey)
        let idStrings = suite.stringArray(forKey: completedSetIdsKey) ?? []
        let completedIds = idStrings.compactMap { UUID(uuidString: $0) }

        guard isDirty || !completedIds.isEmpty else { return nil }

        // Clear pending data
        suite.set(false, forKey: dirtyKey)
        suite.removeObject(forKey: completedSetIdsKey)

        return PendingSync(
            completedSetIds: completedIds,
            isDirty: isDirty,
            currentState: state
        )
    }

    // MARK: - Clear all

    static func clear() {
        suite.removeObject(forKey: stateKey)
        suite.removeObject(forKey: setIdKey)
        suite.removeObject(forKey: restDurationKey)
        suite.set(false, forKey: dirtyKey)
        suite.removeObject(forKey: completedSetIdsKey)
    }
}
