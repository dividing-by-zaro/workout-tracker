import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(filter: #Predicate<Workout> { $0.isInProgress == false }) private var completedWorkouts: [Workout]

    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(AuthService.self) private var authService
    @Environment(WorkoutSyncService.self) private var syncService
    @Environment(AlertSoundService.self) private var alertSoundService

    @State private var showLogoutConfirmation = false

    // MARK: - Derived

    private var initials: String {
        guard let name = authService.userName?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return "K"
        }
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            let first = parts[0].first.map(String.init) ?? ""
            let second = parts[1].first.map(String.init) ?? ""
            return (first + second).uppercased()
        }
        return String(name.first ?? "K").uppercased()
    }

    private var bricksLaid: Int {
        completedWorkouts.reduce(0) { sum, workout in
            sum + workout.exercises.reduce(0) { sub, exercise in
                sub + exercise.sets.filter(\.isCompleted).count
            }
        }
    }

    private var formattedBricksLaid: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: bricksLaid)) ?? "\(bricksLaid)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                header

                // Workouts per week chart
                WorkoutsPerWeekChart(workouts: completedWorkouts)
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                    )
                    .cardShadow()
                    .padding(.horizontal, DesignSystem.Spacing.md)

                // Customizable per-exercise graphs
                ProfileChartsSection(workouts: completedWorkouts)

                // Alert sound picker
                alertSoundCard
                    .padding(.horizontal, DesignSystem.Spacing.md)

                // Sync status & log out
                syncAndLogoutCard
                    .padding(.horizontal, DesignSystem.Spacing.md)

                Color.clear.frame(height: DesignSystem.Spacing.tabBarClearance)
            }
        }
        .brickWallBackground()
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

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                BrickFill(cornerRadius: DesignSystem.CornerRadius.button)
                    .frame(width: 64, height: 64)
                    .mortarShadow()
                Text(initials)
                    .font(DesignSystem.Typography.display(28))
                    .foregroundStyle(DesignSystem.Colors.brickText)
            }

            Text(authService.userName ?? "User")
                .font(DesignSystem.Typography.h1Display)
                .foregroundStyle(DesignSystem.Colors.ink)

            HStack(spacing: 4) {
                Text(formattedBricksLaid)
                    .font(DesignSystem.Typography.mono(16, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.ink2)
                Text("bricks laid")
                    .font(DesignSystem.Typography.italicBody)
                    .foregroundStyle(DesignSystem.Colors.ink3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    // MARK: - Alert sound card

    private var alertSoundCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.ink3)
                Text("Rest Timer Sound")
                    .font(DesignSystem.Typography.sans(14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.ink)
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)

            Divider()
                .foregroundStyle(DesignSystem.Colors.hair)

            ForEach(Array(AlertSound.allCases.enumerated()), id: \.element.id) { index, sound in
                Button {
                    alertSoundService.selected = sound
                    alertSoundService.preview(sound)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        let selected = alertSoundService.selected == sound
                        Circle()
                            .strokeBorder(
                                selected ? DesignSystem.Colors.brick1 : DesignSystem.Colors.ink3,
                                lineWidth: selected ? 5 : 1.5
                            )
                            .frame(width: 18, height: 18)
                        Text(sound.displayName)
                            .font(DesignSystem.Typography.sans(14, weight: .regular))
                            .foregroundStyle(DesignSystem.Colors.ink)
                        Spacer()
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.ink3)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < AlertSound.allCases.count - 1 {
                    Divider()
                        .foregroundStyle(DesignSystem.Colors.hair)
                        .padding(.leading, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .cardShadow()
    }

    // MARK: - Sync + Logout

    private var syncAndLogoutCard: some View {
        VStack(spacing: 0) {
            // Sync status row
            HStack(spacing: DesignSystem.Spacing.sm) {
                if syncService.isSyncing {
                    ProgressView()
                        .tint(DesignSystem.Colors.ink3)
                    Text("Syncing workouts...")
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                } else if syncService.pendingCount == 0 {
                    Image(systemName: "checkmark.icloud")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignSystem.Colors.brick1)
                    Text("All workouts backed up")
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                } else {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignSystem.Colors.ink3)
                    Text("\(syncService.pendingCount) workout\(syncService.pendingCount == 1 ? "" : "s") pending sync")
                        .font(DesignSystem.Typography.sans(14, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.ink2)
                }
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)

            Divider()
                .foregroundStyle(DesignSystem.Colors.hair)

            // Log out row
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignSystem.Colors.red)
                    Text("Log Out")
                        .font(DesignSystem.Typography.sans(14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.red)
                    Spacer()
                }
                .padding(DesignSystem.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .cardShadow()
    }
}
