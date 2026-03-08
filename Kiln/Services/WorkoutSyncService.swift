import Foundation
import SwiftData

@MainActor
@Observable
final class WorkoutSyncService {
    var isSyncing: Bool = false

    private var syncedWorkoutIds: Set<String> {
        didSet { persistSet(syncedWorkoutIds, key: "syncedWorkoutIds") }
    }

    private var pendingEditWorkoutIds: Set<String> {
        didSet { persistSet(pendingEditWorkoutIds, key: "pendingEditWorkoutIds") }
    }

    private var pendingDeleteWorkoutIds: Set<String> {
        didSet { persistSet(pendingDeleteWorkoutIds, key: "pendingDeleteWorkoutIds") }
    }

    var syncedCount: Int { syncedWorkoutIds.count }
    var totalCompletedCount: Int = 0
    var pendingCount: Int { max(0, totalCompletedCount - syncedWorkoutIds.count) }

    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "TimerBackendURL") as? String ?? ""
    }

    private var apiKey: String {
        KeychainService.load(key: "api-key") ?? ""
    }

    init() {
        self.syncedWorkoutIds = Self.loadSet(key: "syncedWorkoutIds")
        self.pendingEditWorkoutIds = Self.loadSet(key: "pendingEditWorkoutIds")
        self.pendingDeleteWorkoutIds = Self.loadSet(key: "pendingDeleteWorkoutIds")
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

        totalCompletedCount = workouts.count
        let localIds = Set(workouts.map { $0.id.uuidString })

        // Reconcile with server: fetch server IDs, rebuild tracking, fix drift
        let serverIds = await fetchServerWorkoutIds()
        if let serverIds {
            // Rebuild syncedWorkoutIds from server truth
            syncedWorkoutIds = serverIds.intersection(localIds)

            // Delete server-side orphans (on server but not on device)
            let orphans = serverIds.subtracting(localIds)
            for localId in orphans {
                let success = await deleteWorkoutFromServer(localId: localId)
                if !success { break }
            }
        }

        // Upload workouts missing from server
        for workout in workouts {
            if syncedWorkoutIds.contains(workout.id.uuidString) { continue }
            let success = await uploadWorkout(workout)
            if !success {
                break
            }
        }

        // Retry pending deletes (deletes before edits — delete supersedes edit)
        for localId in pendingDeleteWorkoutIds {
            let success = await deleteWorkoutFromServer(localId: localId)
            if !success { break }
        }

        // Retry pending edits (skip if also pending delete)
        for localId in pendingEditWorkoutIds {
            if pendingDeleteWorkoutIds.contains(localId) { continue }
            guard let workoutUUID = UUID(uuidString: localId),
                  let workout = workouts.first(where: { $0.id == workoutUUID }) else {
                pendingEditWorkoutIds.remove(localId)
                continue
            }
            let success = await updateWorkout(workout)
            if !success { break }
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

    // MARK: - Update Workout

    func markWorkoutEdited(_ workout: Workout) {
        let localId = workout.id.uuidString
        guard syncedWorkoutIds.contains(localId) else { return }
        pendingEditWorkoutIds.insert(localId)
    }

    @discardableResult
    func updateWorkout(_ workout: Workout) async -> Bool {
        let localId = workout.id.uuidString
        guard !apiKey.isEmpty,
              let url = URL(string: baseURL + "/api/workouts/\(localId)") else { return false }

        let payload = buildPayload(from: workout)
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }

            if http.statusCode == 200 || http.statusCode == 404 {
                pendingEditWorkoutIds.remove(localId)
                return true
            }

            print("WorkoutSync: update HTTP \(http.statusCode) for \(localId)")
            return false
        } catch {
            print("WorkoutSync: update error for \(localId): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Delete Workout

    func markWorkoutDeleted(localId: String) {
        guard syncedWorkoutIds.contains(localId) else { return }
        pendingDeleteWorkoutIds.insert(localId)
        syncedWorkoutIds.remove(localId)
        pendingEditWorkoutIds.remove(localId)
    }

    @discardableResult
    func deleteWorkoutFromServer(localId: String) async -> Bool {
        guard !apiKey.isEmpty,
              let url = URL(string: baseURL + "/api/workouts/\(localId)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }

            if http.statusCode == 200 || http.statusCode == 404 {
                pendingDeleteWorkoutIds.remove(localId)
                return true
            }

            print("WorkoutSync: delete HTTP \(http.statusCode) for \(localId)")
            return false
        } catch {
            print("WorkoutSync: delete error for \(localId): \(error.localizedDescription)")
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

    // MARK: - Server Sync Status

    private func fetchServerWorkoutIds() async -> Set<String>? {
        guard !apiKey.isEmpty,
              let url = URL(string: baseURL + "/api/workouts/ids") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ids = json["local_ids"] as? [String] {
                return Set(ids)
            }
            return nil
        } catch {
            print("WorkoutSync: ids fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchServerSyncCount() async {
        guard !apiKey.isEmpty,
              let url = URL(string: baseURL + "/api/workouts/status") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let count = json["synced_count"] as? Int {
                _ = count // Server count available if needed
            }
        } catch {
            print("WorkoutSync: status fetch error: \(error.localizedDescription)")
        }
    }

    // MARK: - Persistence

    private static func loadSet(key: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    private func persistSet(_ set: Set<String>, key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    // MARK: - ISO 8601 Formatter

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
