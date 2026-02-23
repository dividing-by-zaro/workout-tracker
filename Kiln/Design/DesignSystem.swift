import SwiftUI

enum DesignSystem {

    // MARK: - Colors (Fire Light Theme)

    enum Colors {
        static let primary = Color(red: 0.75, green: 0.20, blue: 0.15)          // Fire red #BF3326
        static let secondary = Color(red: 0.55, green: 0.27, blue: 0.07)        // Warm brown #8B4513
        static let background = Color(red: 0.96, green: 0.94, blue: 0.92)       // Warm cream #F5F0EB
        static let surface = Color.white                                          // White cards
        static let surfaceSecondary = Color(red: 0.93, green: 0.90, blue: 0.87) // Light warm gray #EDE5DD
        static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)      // Near-black #1A1A1A
        static let textSecondary = Color(red: 0.42, green: 0.36, blue: 0.31)    // Warm gray-brown #6B5B4F
        static let textOnPrimary = Color.white                                    // White text on primary buttons
        static let success = Color(red: 0.77, green: 0.53, blue: 0.23)          // Amber/gold #C4873A
        static let destructive = Color(red: 0.58, green: 0.16, blue: 0.12)      // Deep dark red #94291F
        static let timerActive = Color(red: 0.75, green: 0.20, blue: 0.15)      // Fire red (= primary)
        static let timerBackground = Color(red: 0.99, green: 0.91, blue: 0.85)  // Warm peach #FDE8D8
        static let tabBar = Color(red: 0.17, green: 0.09, blue: 0.06)           // Dark warm brown #2C1810
        static let tabInactive = Color(red: 0.62, green: 0.56, blue: 0.51)      // Muted warm gray #9E8E82
    }

    // MARK: - Shadows

    enum Shadows {
        static let cardColor = Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.12)
        static let cardRadius: CGFloat = 8
        static let cardY: CGFloat = 4

        static let elevatedColor = Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.18)
        static let elevatedRadius: CGFloat = 16
        static let elevatedY: CGFloat = 8
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let card: CGFloat = 12
        static let button: CGFloat = 10
        static let chip: CGFloat = 100  // Capsule equivalent
    }

    // MARK: - Typography

    enum Typography {
        static let title: Font = .system(size: 28, weight: .bold)
        static let headline: Font = .system(size: 20, weight: .bold)
        static let body: Font = .system(size: 16, weight: .regular)
        static let caption: Font = .system(size: 12, weight: .regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Icons (SF Symbol names)

    enum Icon {
        static let workout = "dumbbell.fill"
        static let history = "clock.arrow.trianglehead.counterclockwise.rotate.90"
        static let profile = "person.fill"
        static let checkmark = "checkmark.circle.fill"
        static let timer = "timer"
        static let add = "plus"
        static let close = "xmark"
        static let edit = "pencil"
        static let delete = "trash"
    }
}

// MARK: - Grain Texture Overlay

struct GrainedBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var color: Color

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    color.ignoresSafeArea()
                    if !reduceTransparency {
                        Image("noise_tile")
                            .resizable(resizingMode: .tile)
                            .opacity(0.12)
                            .blendMode(.multiply)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
            }
    }
}

struct CardGrainOverlay: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if !reduceTransparency {
            Image("noise_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .blendMode(.multiply)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    func grainedBackground(_ color: Color = DesignSystem.Colors.background) -> some View {
        modifier(GrainedBackground(color: color))
    }

    func cardShadow() -> some View {
        self
            .compositingGroup()
            .shadow(
                color: DesignSystem.Shadows.cardColor,
                radius: DesignSystem.Shadows.cardRadius,
                x: 0,
                y: DesignSystem.Shadows.cardY
            )
    }

    func elevatedShadow() -> some View {
        self
            .compositingGroup()
            .shadow(
                color: DesignSystem.Shadows.elevatedColor,
                radius: DesignSystem.Shadows.elevatedRadius,
                x: 0,
                y: DesignSystem.Shadows.elevatedY
            )
    }
}
