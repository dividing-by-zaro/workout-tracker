import SwiftUI

/// Local design tokens for the widget extension.
///
/// The widget target cannot import the main app's `DesignSystem.swift`,
/// so the small subset of tokens needed for the v3 brickwall Live Activity
/// is duplicated here. All colors resolve to asset-catalog entries in
/// `KilnWidgets/Assets.xcassets/` so palette tweaks happen there.
enum WidgetDesign {
    enum Color {
        static let primary       = SwiftUI.Color("WidgetPrimary")
        static let background    = SwiftUI.Color("WidgetBackground")
        static let surface       = SwiftUI.Color("WidgetSurface")
        static let textPrimary   = SwiftUI.Color("WidgetTextPrimary")
        static let textSecondary = SwiftUI.Color("WidgetTextSecondary")
        static let destructive   = SwiftUI.Color("WidgetDestructive")
        static let timerBg       = SwiftUI.Color("WidgetTimerBackground")
        static let brick1        = SwiftUI.Color("WidgetBrick1")
        static let brick2        = SwiftUI.Color("WidgetBrick2")
        static let brickShade    = SwiftUI.Color("WidgetBrickShade")
        static let brickText     = SwiftUI.Color("WidgetBrickText")
        static let mortar        = SwiftUI.Color("WidgetMortar")
        static let hair          = SwiftUI.Color("WidgetHair")
    }

    // Named `Typo` because `Type` is Swift's reserved metatype keyword:
    // `WidgetDesign.Type` resolves to the metatype, hiding inner members.
    enum Typo {
        /// Display serif (Instrument Serif fallback `.serif`).
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }
        /// Sans (Inter fallback `.default`).
        static func sans(_ size: CGFloat, _ w: Font.Weight = .regular) -> Font {
            .system(size: size, weight: w)
        }
        /// Mono (JetBrains Mono fallback `.monospaced`).
        static func mono(_ size: CGFloat, _ w: Font.Weight = .regular) -> Font {
            .system(size: size, weight: w, design: .monospaced)
        }
    }
}

/// Small brick used as a button surface in the Live Activity.
/// Vertical gradient (brick1 → brick2) plus a stippled speckle overlay
/// drawn in a `Canvas`.
struct BrickFill: View {
    var cornerRadius: CGFloat = 4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetDesign.Color.brick1, WidgetDesign.Color.brick2],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { ctx, size in
                let step: CGFloat = 5
                var y: CGFloat = 1
                while y < size.height {
                    var x: CGFloat = 1
                    while x < size.width {
                        let r = CGRect(x: x - 0.6, y: y - 0.6, width: 1.2, height: 1.2)
                        ctx.fill(Path(ellipseIn: r), with: .color(.black.opacity(0.5)))
                        x += step
                    }
                    y += step
                }
            }
            .opacity(0.12)
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Subtle dual shadow that mimics mortar between bricks.
    func mortarShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: WidgetDesign.Color.brickShade, radius: 0, x: 0, y: 1)
            .shadow(color: WidgetDesign.Color.brickShade.opacity(0.18), radius: 4, x: 0, y: 2)
    }
}
