import SwiftUI

struct CelebrationView: View {
    let data: CelebrationData
    let onDismiss: () -> Void

    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var embers: [Ember] = []
    @State private var animationTime: Double = 0

    var body: some View {
        ZStack {
            // Ember particles
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for ember in embers {
                        let age = now - ember.startTime
                        guard age >= 0, age < ember.lifetime else { continue }
                        let progress = age / ember.lifetime
                        let opacity = 1.0 - progress
                        let y = ember.startY - ember.speed * age
                        let x = ember.startX + sin(age * ember.wobbleFreq) * ember.wobbleAmp
                        let scale = ember.size * (1.0 - progress * 0.5)

                        var shape = context
                        shape.opacity = opacity * 0.8
                        shape.fill(
                            Path(ellipseIn: CGRect(
                                x: x - scale / 2,
                                y: y - scale / 2,
                                width: scale,
                                height: scale
                            )),
                            with: .color(ember.color)
                        )
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Spacer()
                        .frame(height: DesignSystem.Spacing.xxl)

                    // Ordinal workout count
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Your \(data.workoutCount.ordinalString)")
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text("workout")
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Keep the fire burning!")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                    .scaleEffect(showTitle ? 1 : 0.8)
                    .opacity(showTitle ? 1 : 0)

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                    ], spacing: DesignSystem.Spacing.md) {
                        ForEach(Array(visibleStats.enumerated()), id: \.element.id) { index, stat in
                            StatCard(stat: stat)
                                .scaleEffect(showStats ? 1 : 0.8)
                                .opacity(showStats ? 1 : 0)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.1),
                                    value: showStats
                                )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)

                    // Personal records (P3)
                    if !data.personalRecords.isEmpty {
                        personalRecordsSection
                            .scaleEffect(showStats ? 1 : 0.8)
                            .opacity(showStats ? 1 : 0)
                    }

                    Spacer()
                        .frame(height: DesignSystem.Spacing.lg)

                    // Done button
                    Button(action: onDismiss) {
                        Text("Done")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(DesignSystem.Colors.primary)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .opacity(showButton ? 1 : 0)

                    Spacer()
                        .frame(height: DesignSystem.Spacing.lg)
                }
            }
        }
        .grainedBackground()
        .onAppear {
            spawnEmbers()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                showStats = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3 + Double(visibleStats.count) * 0.1 + 0.2)) {
                showButton = true
            }
        }
    }

    // MARK: - Stats

    private var visibleStats: [StatItem] {
        var stats: [StatItem] = []

        // Duration always shows
        stats.append(StatItem(
            icon: "clock.fill",
            value: data.duration,
            label: "duration"
        ))

        // Weight
        if data.hasWeightStats && data.totalVolume > 0 {
            stats.append(StatItem(
                icon: "scalemass.fill",
                value: formatVolume(data.totalVolume),
                label: "lbs lifted"
            ))
        }

        // Sets
        if data.totalSets > 0 {
            stats.append(StatItem(
                icon: "flame.fill",
                value: "\(data.totalSets)",
                label: data.totalSets == 1 ? "set" : "sets"
            ))
        }

        // Reps
        if data.hasRepsStats && data.totalReps > 0 {
            stats.append(StatItem(
                icon: "repeat",
                value: "\(data.totalReps)",
                label: "reps"
            ))
        }

        // Distance
        if data.hasDistanceStats && data.totalDistance > 0 {
            stats.append(StatItem(
                icon: "figure.run",
                value: String(format: "%.1f mi", data.totalDistance),
                label: "distance"
            ))
        }

        return stats
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
    }

    // MARK: - Personal Records Section

    private var personalRecordsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Personal Records")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.bottom, DesignSystem.Spacing.xs)

            ForEach(Array(data.personalRecords.enumerated()), id: \.offset) { _, record in
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(record.exerciseName)
                            .font(DesignSystem.Typography.body.bold())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(record.newBest)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                    Spacer()
                    if let prev = record.previousBest {
                        Text("was \(prev)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                        }
                        .overlay { CardGrainOverlay().clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)) }
                }
                .cardShadow()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    // MARK: - Ember Particles

    private func spawnEmbers() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors: [Color] = [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.success,
            Color(red: 0.95, green: 0.55, blue: 0.20),
            Color(red: 0.90, green: 0.35, blue: 0.15),
            Color(red: 0.85, green: 0.65, blue: 0.25),
        ]
        let now = Date.now.timeIntervalSinceReferenceDate

        embers = (0..<40).map { _ in
            Ember(
                startX: Double.random(in: 0...screenWidth),
                startY: screenHeight * Double.random(in: 0.3...1.0),
                speed: Double.random(in: 80...200),
                size: Double.random(in: 4...10),
                lifetime: Double.random(in: 1.5...3.0),
                startTime: now + Double.random(in: 0...0.6),
                color: colors.randomElement()!,
                wobbleFreq: Double.random(in: 2...5),
                wobbleAmp: Double.random(in: 8...20)
            )
        }
    }
}

// MARK: - Supporting Types

private struct StatItem: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
}

private struct StatCard: View {
    let stat: StatItem

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: stat.icon)
                .font(.system(size: 22))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(stat.value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(stat.label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.surface)
                .overlay { CardGrainOverlay().clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)) }
        }
        .cardShadow()
    }
}

private struct Ember {
    let startX: Double
    let startY: Double
    let speed: Double
    let size: Double
    let lifetime: Double
    let startTime: Double
    let color: Color
    let wobbleFreq: Double
    let wobbleAmp: Double
}
