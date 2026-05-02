import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(WorkoutSyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    private let tabs: [KilnTabBar.TabConfig] = [
        .init(icon: "dumbbell", label: "Workouts", tag: 0),
        .init(icon: "clock", label: "History", tag: 1),
        .init(icon: "list.bullet", label: "Exercises", tag: 2),
        .init(icon: "person", label: "Profile", tag: 3)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    if sessionManager.isWorkoutInProgress {
                        ActiveWorkoutView()
                    } else {
                        StartWorkoutView()
                    }
                case 1:
                    NavigationStack {
                        HistoryListView()
                    }
                case 2:
                    NavigationStack {
                        ExerciseListView()
                    }
                case 3:
                    NavigationStack {
                        ProfileView()
                    }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            KilnTabBar(selection: $selectedTab, tabs: tabs)
        }
        .tint(DesignSystem.Colors.brick2)
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
        .task {
            await syncService.syncAllPending(context: modelContext)
        }
        .onChange(of: sessionManager.shouldSwitchToWorkoutTab) {
            if sessionManager.shouldSwitchToWorkoutTab {
                selectedTab = 0
                sessionManager.shouldSwitchToWorkoutTab = false
            }
        }
    }
}

// MARK: - KilnTabBar

private struct KilnTabBar: View {
    struct TabConfig: Identifiable {
        let icon: String
        let label: String
        let tag: Int
        var id: Int { tag }
    }

    @Binding var selection: Int
    let tabs: [TabConfig]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                Button {
                    selection = tab.tag
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(
                                selection == tab.tag
                                    ? DesignSystem.Colors.brick2
                                    : DesignSystem.Colors.ink3
                            )
                        Text(tab.label)
                            .font(DesignSystem.Typography.sans(10, weight: .semibold))
                            .foregroundStyle(
                                selection == tab.tag
                                    ? DesignSystem.Colors.brick2
                                    : DesignSystem.Colors.ink3
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == tab.tag {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DesignSystem.Colors.tabActiveBg)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .background(DesignSystem.Colors.card.opacity(0.94))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.tabBar)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.tabBar))
        .elevatedShadow()
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
    }
}
