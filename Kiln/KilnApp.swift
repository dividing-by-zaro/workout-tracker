import SwiftUI
import SwiftData

@main
struct KilnApp: App {
    @State private var sessionManager = WorkoutSessionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
                .preferredColorScheme(.light)
                .onAppear {
                    // Crash recovery: check for interrupted workout on launch
                }
                .onOpenURL { url in
                    // Handle kiln://active-workout deep link from Live Activity
                    // The app is already showing the active workout in the Workout tab
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
                sessionManager.handleForegroundResume()
            }
        }
    }
}
