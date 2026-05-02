import SwiftUI

/// Fired-clay brick fill — used for completed set rows and brick-CTA buttons.
///
/// Vertical gradient `brick1 → brick2`, sharp `brick: 4` corner, mortar shadow,
/// and a 12% radial-dot speckle overlay for the clay grain.
struct BrickFill: View {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.brick

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.Colors.brick1, DesignSystem.Colors.brick2],
                startPoint: .top,
                endPoint: .bottom
            )
            BrickSpeckle()
                .opacity(0.12)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Radial-dot pattern that gives the brick its clay grain.
/// 0.6pt dots on a 5×5 grid, drawn in pure black so the parent's `.opacity(0.12)`
/// controls overall strength.
struct BrickSpeckle: View {
    var body: some View {
        Canvas { context, size in
            let dot = CGSize(width: 1.2, height: 1.2)
            let step: CGFloat = 5
            var y: CGFloat = 1
            while y < size.height {
                var x: CGFloat = 1
                while x < size.width {
                    let rect = CGRect(
                        x: x - dot.width / 2,
                        y: y - dot.height / 2,
                        width: dot.width,
                        height: dot.height
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.5)))
                    x += step
                }
                y += step
            }
        }
        .allowsHitTesting(false)
    }
}

/// Signed-margin stagger inset — applies to a brick row to create the running-bond
/// effect without ever using `.offset()` (which would break layout measurements).
///
/// `marginLeft = INSET + offset`, `marginRight = INSET - offset`.
/// The two margins always sum to `2 * INSET`, so total horizontal space is constant
/// and the wall stays visually centered.
struct BrickStaggerInset: ViewModifier {
    let offset: CGFloat
    var inset: CGFloat = DesignSystem.Spacing.brickInset

    func body(content: Content) -> some View {
        content
            .padding(.leading, inset + offset)
            .padding(.trailing, inset - offset)
    }
}

extension View {
    /// Apply running-bond stagger margins to a brick row.
    /// Use `+offset` to shift right, `-offset` to shift left. Adjacent bricks
    /// alternate around 0; the spec uses `[-7, +7, -7, +7, …]`.
    func brickStagger(offset: CGFloat) -> some View {
        modifier(BrickStaggerInset(offset: offset))
    }
}

/// Brick-CTA button background (e.g. Live Activity "Done" button, primary CTAs).
/// Same gradient + speckle + mortar shadow as a set-row brick.
struct BrickButtonBackground: View {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.brick

    var body: some View {
        BrickFill(cornerRadius: cornerRadius)
    }
}

/// Convenience: returns the offset for the Nth completed brick using the
/// canonical `[-7, +7, -7, +7, …]` running-bond pattern.
enum BrickStagger {
    static let amount: CGFloat = 7

    static func offset(for index: Int) -> CGFloat {
        index % 2 == 0 ? -amount : +amount
    }
}
