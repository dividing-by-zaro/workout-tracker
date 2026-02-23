import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.tabBar)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignSystem.Colors.tabInactive)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.tabInactive)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

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
                Label("Workouts", systemImage: DesignSystem.Icon.workout)
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
