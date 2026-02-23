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
                .onAppear {
                    // Crash recovery: check for interrupted workout on launch
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
                sessionManager.restTimer.syncFromPersistedState()
            }
        }
    }
}
