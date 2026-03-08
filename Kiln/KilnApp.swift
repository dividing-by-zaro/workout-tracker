import SwiftUI
import SwiftData

@main
struct KilnApp: App {
    @State private var sessionManager = WorkoutSessionManager()
    @State private var authService = AuthService()
    @State private var syncService = WorkoutSyncService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environment(sessionManager)
                        .onAppear {
                            sessionManager.notificationService.requestPermission()
                        }
                        .onOpenURL { url in
                            sessionManager.shouldSwitchToWorkoutTab = true
                        }
                } else if authService.state == .checking {
                    // Brief loading state while checking Keychain
                    Color.clear
                        .grainedBackground()
                } else {
                    LoginView()
                }
            }
            .environment(authService)
            .environment(syncService)
            .preferredColorScheme(.light)
            .onAppear {
                authService.checkStoredAuth()
            }
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self
        ], isAutosaveEnabled: false)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                if authService.isAuthenticated {
                    sessionManager.handleForegroundResume()
                }
            }
        }
    }
}
