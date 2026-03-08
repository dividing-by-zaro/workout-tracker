import Foundation

enum AuthState {
    case checking
    case unauthenticated
    case authenticating
    case authenticated
}

@MainActor
@Observable
final class AuthService {
    var state: AuthState = .checking
    var userName: String?
    var errorMessage: String?

    var isAuthenticated: Bool { state == .authenticated }

    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "TimerBackendURL") as? String ?? ""
    }

    func checkStoredAuth() {
        guard let storedKey = KeychainService.load(key: "api-key") else {
            state = .unauthenticated
            return
        }

        // Immediately show app with cached profile
        userName = UserDefaults.standard.string(forKey: "cachedUserName")
        state = .authenticated

        // Silently validate with backend in background
        Task {
            await silentValidate(apiKey: storedKey)
        }
    }

    private func silentValidate(apiKey: String) async {
        guard let url = URL(string: baseURL + "/api/me") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }

            if http.statusCode == 401 {
                // Key revoked — force logout
                KeychainService.delete(key: "api-key")
                UserDefaults.standard.removeObject(forKey: "cachedUserName")
                UserDefaults.standard.removeObject(forKey: "cachedUserProfileAt")
                userName = nil
                state = .unauthenticated
                return
            }

            if http.statusCode == 200 {
                // Refresh cached profile
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let name = json?["name"] as? String
                UserDefaults.standard.set(name, forKey: "cachedUserName")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cachedUserProfileAt")
                userName = name
            }
        } catch {
            // Network error — stay authenticated with cached data
        }
    }

    func login(apiKey: String) async {
        state = .authenticating
        errorMessage = nil

        guard let url = URL(string: baseURL + "/api/me") else {
            errorMessage = "Could not reach server. Check your connection."
            state = .unauthenticated
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                errorMessage = "Could not reach server. Check your connection."
                state = .unauthenticated
                return
            }

            guard http.statusCode == 200 else {
                errorMessage = "Invalid API key"
                state = .unauthenticated
                return
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let name = json?["name"] as? String

            KeychainService.save(key: "api-key", value: apiKey)
            UserDefaults.standard.set(name, forKey: "cachedUserName")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cachedUserProfileAt")

            userName = name
            state = .authenticated
        } catch {
            errorMessage = "Could not reach server. Check your connection."
            state = .unauthenticated
        }
    }

    func logout() {
        KeychainService.delete(key: "api-key")
        UserDefaults.standard.removeObject(forKey: "cachedUserName")
        UserDefaults.standard.removeObject(forKey: "cachedUserProfileAt")
        userName = nil
        state = .unauthenticated
    }
}
