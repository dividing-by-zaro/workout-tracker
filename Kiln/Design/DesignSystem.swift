import SwiftUI

enum DesignSystem {

    // MARK: - Colors (Kiln v3 — fired clay / parchment palette)

    enum Colors {
        // Surfaces
        static let bg              = Color(red: 0xF2/255.0, green: 0xED/255.0, blue: 0xE3/255.0)   // #F2EDE3
        static let bgDeeper        = Color(red: 0xE8/255.0, green: 0xDF/255.0, blue: 0xCE/255.0)   // #E8DFCE — brick wall mortar tone
        static let card            = Color.white                                                    // #FFFFFF
        static let cardEdge        = Color.black.opacity(0.06)
        static let hair            = Color.black.opacity(0.06)
        static let mortar          = Color(red: 0xE8/255.0, green: 0xDD/255.0, blue: 0xC9/255.0)   // #E8DDC9 — rest timer fill

        // Ink (text)
        static let ink             = Color(red: 0x1B/255.0, green: 0x16/255.0, blue: 0x12/255.0)   // #1B1612
        static let ink2            = Color(red: 0x5C/255.0, green: 0x54/255.0, blue: 0x4A/255.0)   // #5C544A
        static let ink3            = Color(red: 0x9A/255.0, green: 0x90/255.0, blue: 0x89/255.0)   // #9A9089

        // Brick accent family
        static let brick1          = Color(red: 0xB8/255.0, green: 0x54/255.0, blue: 0x3A/255.0)   // #B8543A
        static let brick2          = Color(red: 0x9C/255.0, green: 0x3E/255.0, blue: 0x26/255.0)   // #9C3E26
        static let brickShade      = Color(red: 0x7A/255.0, green: 0x2D/255.0, blue: 0x18/255.0)   // #7A2D18
        static let brickText       = Color(red: 0xFB/255.0, green: 0xE8/255.0, blue: 0xDA/255.0)   // #FBE8DA
        static let accent          = Color(red: 0xC2/255.0, green: 0x6B/255.0, blue: 0x3F/255.0)   // #C26B3F
        static let red             = Color(red: 0xB4/255.0, green: 0x3B/255.0, blue: 0x2E/255.0)   // #B43B2E

        // Tab bar active pill
        static let tabActiveBg     = Color(red: 0xF4/255.0, green: 0xE5/255.0, blue: 0xD7/255.0)   // #F4E5D7
        static let tabActiveText   = Color(red: 0x9C/255.0, green: 0x3E/255.0, blue: 0x26/255.0)   // = brick2

        // MARK: Legacy aliases (kept so unmigrated callsites still compile/look reasonable)
        static let primary         = brick1
        static let secondary       = ink2
        static let background      = bg
        static let surface         = card
        static let surfaceSecondary = bgDeeper
        static let textPrimary     = ink
        static let textSecondary   = ink2
        static let textOnPrimary   = brickText
        static let success         = brick1
        static let destructive     = red
        static let timerActive     = brick1
        static let timerBackground = mortar
        static let tabBar          = card
        static let tabInactive     = ink3

        // Charts
        static let chartLine       = brick1
        static let chartArea       = brick1.opacity(0.14)
        static let chartGrid       = ink3.opacity(0.18)
    }

    // MARK: - Shadows

    enum Shadows {
        // Default subtle card shadow (sheets-of-paper).
        static let cardColor: Color    = Color.black.opacity(0.02)
        static let cardRadius: CGFloat = 1.5
        static let cardY: CGFloat      = 1

        // Heavier shadow for floating tab bar / modal sheets.
        static let elevatedColor: Color   = Color.black.opacity(0.08)
        static let elevatedRadius: CGFloat = 24
        static let elevatedY: CGFloat     = 10

        // Mortar shadow for bricks and brick CTAs.
        static let mortarHardColor: Color   = Color(red: 0x7A/255.0, green: 0x2D/255.0, blue: 0x18/255.0)
        static let mortarAmbientColor: Color = Color(red: 0x7A/255.0, green: 0x2D/255.0, blue: 0x18/255.0).opacity(0.18)
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let card: CGFloat   = 14
        static let brick: CGFloat  = 4
        static let tabBar: CGFloat = 14
        static let pill: CGFloat   = 999
        static let button: CGFloat = 8
        static let chip: CGFloat   = 999  // legacy alias
    }

    // MARK: - Typography
    //
    // Font families are loaded if bundled, otherwise mapped to closest system fallbacks.
    //   display       — Instrument Serif      → fallback `.system(.title, design: .serif)`
    //   serifItalic   — Fraunces (italic)     → fallback Georgia italic
    //   sans          — Inter                 → fallback SF Pro
    //   mono          — JetBrains Mono        → fallback SF Mono / monospaced
    //
    // The helpers below try the bundled family first, fall back if the font is missing.

    enum Typography {
        // MARK: Family helpers
        //
        // Until the custom .ttf files are bundled, every helper returns a SwiftUI
        // system font in the closest design family. When the fonts are added later,
        // swap the implementations to `Font.custom("InstrumentSerif-Regular", size:)`,
        // etc. — call sites already pass the size + weight so no further changes
        // are required at the consumer level.

        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }

        static func serifItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .serif).italic()
        }

        static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        // MARK: Type scale (per spec §3.1)

        /// Workout title — Instrument Serif 34/400, tracking -0.6, line-height 1.
        static let h1Display      = display(34)
        /// Exercise name — Instrument Serif 22/400, tracking -0.3.
        static let h2Display      = display(22)
        /// Eyebrow — Fraunces italic 11/500 letter-spacing 2 uppercase.
        static let eyebrow        = serifItalic(11, weight: .medium)
        /// Section labels (FIRING / COOLING) — Inter 10/700.
        static let sectionLabel   = sans(10, weight: .bold)
        /// Body / placeholder note — Fraunces italic 13.
        static let italicBody     = serifItalic(13)
        /// UI buttons — Inter 13/600.
        static let button         = sans(13, weight: .semibold)
        /// Inter 14/600 for primary buttons in larger contexts.
        static let buttonLarge    = sans(14, weight: .semibold)
        /// Helper / muted — Inter 11/500.
        static let helper         = sans(11, weight: .medium)
        /// Helper 12.
        static let helper12       = sans(12, weight: .medium)
        /// Set index — Mono 10/700, tabular.
        static let setIndex       = mono(10, weight: .bold)
        /// Prev line — Mono 11/400, tabular.
        static let prevLine       = mono(11, weight: .regular)
        /// Rest timer numerals — Mono 22/700, tracking -0.4.
        static let restTimer      = mono(22, weight: .bold)
        /// Brick weight/reps — Mono 15/700, tracking -0.3.
        static let brickValue     = mono(15, weight: .bold)
        /// Live activity timer — Mono 38/700.
        static let liveTimer      = mono(38, weight: .bold)

        // MARK: Legacy aliases — old `title/headline/body/label/caption`

        static let title: Font     = h1Display
        static let headline: Font  = h2Display
        static let body: Font      = sans(14, weight: .regular)
        static let label: Font     = sans(13, weight: .semibold)
        static let caption: Font   = sans(12, weight: .regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48

        // Page rhythm (per spec §5.2)
        static let padPage: CGFloat       = 18
        static let padCardOuter: CGFloat  = 14
        static let padCardInner: CGFloat  = 14
        static let gapCard: CGFloat       = 12
        static let gapBrick: CGFloat      = 4
        static let tabBarClearance: CGFloat = 80

        // Brick centerline inset (signed offsets sum to 0 around this).
        static let brickInset: CGFloat    = 8
    }

    // MARK: - Icons (legacy SF Symbol names — still consumed in a few places)

    enum Icon {
        static let workout    = "dumbbell"          // stroke variant
        static let history    = "clock"
        static let profile    = "person"
        static let exercises  = "list.bullet"
        static let checkmark  = "checkmark"
        static let timer      = "timer"
        static let add        = "plus"
        static let close      = "xmark"
        static let edit       = "pencil"
        static let delete     = "trash"
    }
}

// MARK: - Background — parchment with subtle grain

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
                            .opacity(0.07)
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
                .opacity(0.04)
                .blendMode(.multiply)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    func grainedBackground(_ color: Color = DesignSystem.Colors.bg) -> some View {
        modifier(GrainedBackground(color: color))
    }

    /// Subtle paper-on-surface shadow (default card).
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

    /// Heavier shadow used for the floating tab bar and modal sheets.
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

    /// Mortar shadow used for bricks and brick-CTA buttons.
    /// `0 1px 0 brickShade, 0 2px 4px rgba(122,45,24,.18)`
    func mortarShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: DesignSystem.Shadows.mortarHardColor, radius: 0, x: 0, y: 1)
            .shadow(color: DesignSystem.Shadows.mortarAmbientColor, radius: 4, x: 0, y: 2)
    }
}
