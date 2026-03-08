import Foundation

@MainActor
final class TimerBackendService {
    private let baseURL: String

    private var apiKey: String {
        KeychainService.load(key: "api-key") ?? ""
    }

    init() {
        self.baseURL = Bundle.main.object(forInfoDictionaryKey: "TimerBackendURL") as? String ?? ""
    }

    func scheduleTimer(
        pushToken: String,
        duration: Int,
        contentState: [String: Any],
        deviceId: String
    ) {
        guard !apiKey.isEmpty, !pushToken.isEmpty else { return }

        let body: [String: Any] = [
            "push_token": pushToken,
            "duration_seconds": duration,
            "content_state": contentState,
            "device_id": deviceId
        ]

        post(path: "/api/timer/schedule", body: body)
    }

    func cancelTimer(deviceId: String) {
        guard !apiKey.isEmpty else { return }

        let body: [String: Any] = [
            "device_id": deviceId
        ]

        post(path: "/api/timer/cancel", body: body)
    }

    // MARK: - Private

    private func post(path: String, body: [String: Any]) {
        guard let url = URL(string: baseURL + path),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        Task.detached {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    print("TimerBackend \(path) failed: HTTP \(http.statusCode)")
                }
            } catch {
                print("TimerBackend \(path) error: \(error.localizedDescription)")
            }
        }
    }
}
