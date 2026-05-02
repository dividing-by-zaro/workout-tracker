import SwiftUI

/// Running-bond brick wall texture used as the Active Workout screen background.
/// Tile is 60×30 with mortar lines drawn into the bgDeeper fill.
struct BrickWallBackground: View {
    var body: some View {
        Canvas { context, size in
            // Fill base
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(DesignSystem.Colors.bgDeeper)
            )

            let mortar = Color(red: 60/255.0, green: 40/255.0, blue: 25/255.0).opacity(0.13)
            let strokeStyle = StrokeStyle(lineWidth: 1, lineCap: .square)

            let tileW: CGFloat = 60
            let tileH: CGFloat = 30
            let halfH: CGFloat = 15

            // Horizontal mortar lines every 15 px
            var y: CGFloat = 0
            while y <= size.height + 1 {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(mortar), style: strokeStyle)
                y += halfH
            }

            // Vertical mortar lines, alternating per row.
            var rowTop: CGFloat = 0
            var rowIdx = 0
            while rowTop < size.height {
                let rowBottom = rowTop + halfH
                // Row 0 (and even): joints at x = 0, 30, 60, … (multiples of tileW)
                // Row 1 (odd):       joints at x = 15, 45, 75, …
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
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Tile a running-bond brick wall behind this view.
    func brickWallBackground() -> some View {
        background(BrickWallBackground())
    }
}
