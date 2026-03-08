import Foundation
import SwiftData

@MainActor
@Observable
final class WorkoutSyncService {
    var isSyncing: Bool = false

    private var syncedWorkoutIds: Set<String> {
        didSet { persistSyncedIds() }
    }

    var syncedCount: Int { syncedWorkoutIds.count }

    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "TimerBackendURL") as? String ?? ""
    }

    private var apiKey: String {
        KeychainService.load(key: "api-key") ?? ""
    }

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: "syncedWorkoutIds") ?? []
        self.syncedWorkoutIds = Set(stored)
    }

    // MARK: - Bulk Sync

    func syncAllPending(context: ModelContext) async {
        guard !isSyncing, !apiKey.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }

        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isInProgress == false }
        )
        guard let workouts = try? context.fetch(descriptor) else { return }

        for workout in workouts {
            if syncedWorkoutIds.contains(workout.id.uuidString) { continue }
            let success = await uploadWorkout(workout)
            if !success {
                // Network/server error — stop bulk sync, retry next launch
                break
            }
        }
    }

    // MARK: - Single Workout Upload

    @discardableResult
    func uploadWorkout(_ workout: Workout) async -> Bool {
        guard !apiKey.isEmpty,
              let url = URL(string: baseURL + "/api/workouts") else { return false }

        let localId = workout.id.uuidString

        // Already synced
        if syncedWorkoutIds.contains(localId) { return true }

        let payload = buildPayload(from: workout)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }

            if http.statusCode == 201 || http.statusCode == 200 {
                syncedWorkoutIds.insert(localId)
                return true
            }

            // 422 = malformed data, don't retry
            if http.statusCode == 422 {
                print("WorkoutSync: 422 for \(localId), skipping")
                syncedWorkoutIds.insert(localId)
                return true
            }

            print("WorkoutSync: HTTP \(http.statusCode) for \(localId)")
            return false
        } catch {
            print("WorkoutSync: error for \(localId): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Payload Builder

    private func buildPayload(from workout: Workout) -> [String: Any] {
        let exercises: [[String: Any]] = workout.sortedExercises.map { workoutExercise in
            let sets: [[String: Any?]] = workoutExercise.sortedSets.filter(\.isCompleted).map { set in
                [
                    "order": set.order,
                    "weight": set.weight,
                    "reps": set.reps,
                    "distance": set.distance,
                    "seconds": set.seconds,
                    "rpe": set.rpe,
                    "completed_at": set.completedAt.map { Self.isoFormatter.string(from: $0) },
                ]
            }

            let exercise = workoutExercise.exercise
            return [
                "order": workoutExercise.order,
                "exercise_name": exercise?.name ?? "Unknown",
                "exercise_type": exercise?.exerciseType.rawValue ?? "strength",
                "body_part": exercise?.bodyPart?.rawValue as Any,
                "equipment_type": exercise?.equipmentType?.rawValue as Any,
                "sets": sets.map { dict in
                    dict.compactMapValues { $0 }
                },
            ] as [String: Any]
        }

        var payload: [String: Any] = [
            "local_id": workout.id.uuidString,
            "name": workout.name,
            "started_at": Self.isoFormatter.string(from: workout.startedAt),
            "completed_at": Self.isoFormatter.string(from: workout.completedAt ?? workout.startedAt),
            "exercises": exercises,
        ]

        if let duration = workout.durationSeconds {
            payload["duration_seconds"] = duration
        }

        return payload
    }

    // MARK: - Persistence

    private func persistSyncedIds() {
        UserDefaults.standard.set(Array(syncedWorkoutIds), forKey: "syncedWorkoutIds")
    }

    // MARK: - ISO 8601 Formatter

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
