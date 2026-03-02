import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

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
        TabView(selection: $selectedTab) {
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
            .tag(0)

            NavigationStack {
                HistoryListView()
            }
            .tabItem {
                Label("History", systemImage: DesignSystem.Icon.history)
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: DesignSystem.Icon.profile)
            }
            .tag(2)
        }
        .tint(DesignSystem.Colors.primary)
        .fullScreenCover(isPresented: Binding(
            get: { sessionManager.celebrationData != nil },
            set: { if !$0 { sessionManager.celebrationData = nil } }
        )) {
            if let data = sessionManager.celebrationData {
                CelebrationView(data: data, onDismiss: {
                    sessionManager.celebrationData = nil
                })
            } else {
                Color.clear.onAppear { sessionManager.celebrationData = nil }
            }
        }
        .onAppear {
            sessionManager.checkForInterruptedWorkout(context: modelContext)
        }
        .onChange(of: sessionManager.shouldSwitchToWorkoutTab) {
            if sessionManager.shouldSwitchToWorkoutTab {
                selectedTab = 0
                sessionManager.shouldSwitchToWorkoutTab = false
            }
        }
    }
}
