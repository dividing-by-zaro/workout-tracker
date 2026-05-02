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
                        shape.opacity = opacity * 0.7
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

                    // Title block
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("SESSION NO. \(data.workoutCount)")
                            .font(DesignSystem.Typography.eyebrow)
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignSystem.Colors.ink3)

                        Text("\(data.workoutCount)")
                            .font(DesignSystem.Typography.mono(64, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.brick1)

                        Text("Another brick laid.")
                            .font(DesignSystem.Typography.italicBody)
                            .foregroundStyle(DesignSystem.Colors.ink3)
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
                    .padding(.horizontal, DesignSystem.Spacing.padCardOuter)

                    // Personal records
                    if !data.personalRecords.isEmpty {
                        personalRecordsSection
                            .scaleEffect(showStats ? 1 : 0.8)
                            .opacity(showStats ? 1 : 0)
                    }

                    Spacer()
                        .frame(height: DesignSystem.Spacing.lg)

                    // Done button — brick CTA
                    Button(action: onDismiss) {
                        Text("Done")
                            .font(DesignSystem.Typography.buttonLarge)
                            .foregroundStyle(DesignSystem.Colors.brickText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(BrickButtonBackground(cornerRadius: 8))
                            .mortarShadow()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .opacity(showButton ? 1 : 0)

                    Spacer()
                        .frame(height: DesignSystem.Spacing.lg)
                }
            }
        }
        .brickWallBackground()
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
            iconKind: .system("clock"),
            value: data.duration,
            label: "duration"
        ))

        // Weight
        if data.hasWeightStats && data.totalVolume > 0 {
            stats.append(StatItem(
                iconKind: .system("square.grid.3x3"),
                value: formatVolume(data.totalVolume),
                label: "lbs lifted"
            ))
        }

        // Sets — render as brick icon (the hero metaphor)
        if data.totalSets > 0 {
            stats.append(StatItem(
                iconKind: .asset("brick_icon"),
                value: "\(data.totalSets)",
                label: data.totalSets == 1 ? "set" : "sets"
            ))
        }

        // Reps
        if data.hasRepsStats && data.totalReps > 0 {
            stats.append(StatItem(
                iconKind: .system("arrow.clockwise"),
                value: "\(data.totalReps)",
                label: "reps"
            ))
        }

        // Distance
        if data.hasDistanceStats && data.totalDistance > 0 {
            stats.append(StatItem(
                iconKind: .system("arrow.right"),
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
                Image(systemName: "trophy")
                    .foregroundStyle(DesignSystem.Colors.brick1)
                Text("Personal Records")
                    .font(DesignSystem.Typography.h2Display)
                    .foregroundStyle(DesignSystem.Colors.ink)
            }
            .padding(.bottom, DesignSystem.Spacing.xs)

            ForEach(Array(data.personalRecords.enumerated()), id: \.offset) { _, record in
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(record.exerciseName)
                            .font(DesignSystem.Typography.sans(14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.ink)
                        Text(record.newBest)
                            .font(DesignSystem.Typography.mono(14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.brick1)
                    }
                    Spacer()
                    if let prev = record.previousBest {
                        Text("was \(prev)")
                            .font(DesignSystem.Typography.helper)
                            .foregroundStyle(DesignSystem.Colors.ink3)
                    }
                }
                .padding(DesignSystem.Spacing.padCardInner)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                        .fill(DesignSystem.Colors.card)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                                .stroke(DesignSystem.Colors.brick1.opacity(0.3), lineWidth: 1)
                        }
                }
                .cardShadow()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.padCardOuter)
    }

    // MARK: - Ember Particles

    private func spawnEmbers() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors: [Color] = [
            DesignSystem.Colors.brick1,
            DesignSystem.Colors.brick2,
            DesignSystem.Colors.accent,
            Color(red: 0.85, green: 0.55, blue: 0.40),
            Color(red: 0.78, green: 0.42, blue: 0.30),
        ]
        let now = Date.now.timeIntervalSinceReferenceDate

        embers = (0..<24).map { _ in
            Ember(
                startX: Double.random(in: 0...screenWidth),
                startY: screenHeight * Double.random(in: 0.3...1.0),
                speed: Double.random(in: 60...140),
                size: Double.random(in: 4...10),
                lifetime: Double.random(in: 1.5...3.0),
                startTime: now + Double.random(in: 0...0.6),
                color: colors.randomElement()!,
                wobbleFreq: Double.random(in: 2...5),
                wobbleAmp: Double.random(in: 4...12)
            )
        }
    }
}

// MARK: - Supporting Types

private enum StatIconKind {
    case system(String)
    case asset(String)
}

private struct StatItem: Identifiable {
    let id = UUID()
    let iconKind: StatIconKind
    let value: String
    let label: String
}

private struct StatCard: View {
    let stat: StatItem

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            iconView
                .foregroundStyle(DesignSystem.Colors.brick1)
                .frame(height: 24)

            Text(stat.value)
                .font(DesignSystem.Typography.mono(24, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(stat.label)
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                        .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                }
        }
        .cardShadow()
    }

    @ViewBuilder
    private var iconView: some View {
        switch stat.iconKind {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 22, weight: .regular))
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
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
