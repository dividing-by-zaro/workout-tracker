import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isInProgress == false }) private var completedWorkouts: [Workout]

    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(AuthService.self) private var authService
    @Environment(WorkoutSyncService.self) private var syncService

    @State private var showLogoutConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Profile header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Text(authService.userName ?? "User")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(completedWorkouts.count) workouts")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Chart
                WorkoutsPerWeekChart(workouts: completedWorkouts)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                    .cardShadow()
                    .padding(.horizontal, DesignSystem.Spacing.md)

                // Sync status & Log out grouped card
                VStack(spacing: 0) {
                    // Sync status row
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if syncService.isSyncing {
                            ProgressView()
                                .tint(DesignSystem.Colors.primary)
                            Text("Syncing workouts...")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        } else if syncService.pendingCount == 0 {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundStyle(DesignSystem.Colors.primary)
                            Text("All workouts backed up")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(DesignSystem.Colors.primary)
                            Text("\(syncService.pendingCount) workout\(syncService.pendingCount == 1 ? "" : "s") pending sync")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)

                    Divider()
                        .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.15))

                    // Log out row
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Text("Log Out")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                .cardShadow()
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .grainedBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncService.totalCompletedCount = completedWorkouts.count
        }
        .alert("Log out of Kiln?", isPresented: $showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                if sessionManager.activeWorkout != nil {
                    sessionManager.reset()
                }
                authService.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if sessionManager.activeWorkout != nil {
                Text("Your active workout will be lost.")
            } else {
                Text("You'll need to enter your API key to log back in.")
            }
        }
    }
}
