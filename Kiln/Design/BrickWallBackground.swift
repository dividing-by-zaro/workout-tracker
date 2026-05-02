import SwiftUI

/// Running-bond brick wall texture used as the Active Workout screen background.
///
/// Tile is 60×30 with mortar lines drawn over a `bgDeeper` base. Rendered with a
/// `Canvas` sized to its parent. Use either as a ZStack base or via the
/// `.brickWallBackground()` modifier.
struct BrickWallBackground: View {
    var body: some View {
        ZStack {
            // Solid base — guarantees the fired-clay parchment shows even if the
            // Canvas can't render (e.g. on a constrained widget surface).
            DesignSystem.Colors.bgDeeper

            Canvas { context, size in
                let mortar = Color(red: 60/255.0, green: 40/255.0, blue: 25/255.0).opacity(0.20)
                let strokeStyle = StrokeStyle(lineWidth: 1, lineCap: .square)

                let tileW: CGFloat = 60
                let halfH: CGFloat = 15

                // Horizontal mortar lines every 15 px.
                var y: CGFloat = 0
                while y <= size.height + 1 {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(p, with: .color(mortar), style: strokeStyle)
                    y += halfH
                }

                // Vertical mortar lines, alternating per row (running bond).
                var rowTop: CGFloat = 0
                var rowIdx = 0
                while rowTop < size.height {
                    let rowBottom = rowTop + halfH
                    let xOffset: CGFloat = (rowIdx % 2 == 0) ? 0 : 15
                    var x = xOffset
                    while x <= size.width + 1 {
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: rowTop))
                        p.addLine(to: CGPoint(x: x, y: rowBottom))
                        context.stroke(p, with: .color(mortar), style: strokeStyle)
                        x += tileW
                    }
                    rowTop += halfH
                    rowIdx += 1
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Tile a running-bond brick wall behind this view.
    /// Implemented via a ZStack base (not `.background(…)`) because `.background`
    /// does not propagate `.ignoresSafeArea` from the inner view.
    func brickWallBackground() -> some View {
        ZStack {
            BrickWallBackground()
            self
        }
    }
}
