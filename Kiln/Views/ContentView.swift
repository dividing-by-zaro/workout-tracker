import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Group {
                if sessionManager.isWorkoutInProgress {
                    ActiveWorkoutView()
                } else {
                    StartWorkoutView()
                }
            }
            .tabItem {
                Label("Workout", systemImage: DesignSystem.Icon.workout)
            }

            NavigationStack {
                HistoryListView()
            }
            .tabItem {
                Label("History", systemImage: DesignSystem.Icon.history)
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: DesignSystem.Icon.profile)
            }
        }
        .tint(DesignSystem.Colors.primary)
        .onAppear {
            sessionManager.checkForInterruptedWorkout(context: modelContext)
        }
    }
}
