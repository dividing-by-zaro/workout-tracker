import SwiftUI
import UIKit

/// Running-bond brick wall texture used as the Active Workout screen background.
///
/// Renders as a tiled `UIImage` (60×30 tile) over a `bgDeeper` base. Tiled bitmaps
/// are far more reliable than `Canvas` when used as a background — they always
/// draw, always fill, and don't depend on layout-pass timing.
struct BrickWallBackground: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.bgDeeper
            Image(uiImage: BrickWallBackground.tile)
                .resizable(resizingMode: .tile)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // Cached tile bitmap — generated once.
    private static let tile: UIImage = makeTile()

    private static func makeTile() -> UIImage {
        let size = CGSize(width: 60, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext

            // Base fill — bgDeeper #E8DFCE
            cg.setFillColor(UIColor(red: 0xE8/255.0, green: 0xDF/255.0, blue: 0xCE/255.0, alpha: 1).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            // Mortar joint color — warm dark brown at 22% so it reads on the parchment.
            cg.setStrokeColor(UIColor(red: 60/255.0, green: 40/255.0, blue: 25/255.0, alpha: 0.22).cgColor)
            cg.setLineWidth(1)
            cg.setLineCap(.square)

            // Horizontal mortar lines: y = 0, 15, 30.
            for y in stride(from: 0.0, through: 30.0, by: 15.0) {
                cg.move(to: CGPoint(x: 0, y: y))
                cg.addLine(to: CGPoint(x: 60, y: y))
            }
            // Row 1 verticals (y 0–15): joints at x = 0, 30, 60.
            for x in [0.0, 30.0, 60.0] {
                cg.move(to: CGPoint(x: x, y: 0))
                cg.addLine(to: CGPoint(x: x, y: 15))
            }
            // Row 2 verticals (y 15–30): half-brick offset, joints at x = 15, 45.
            for x in [15.0, 45.0] {
                cg.move(to: CGPoint(x: x, y: 15))
                cg.addLine(to: CGPoint(x: x, y: 30))
            }
            cg.strokePath()
        }
    }
}

extension View {
    /// Place a running-bond brick wall behind this view, full-bleed.
    /// Implemented via a ZStack base (not `.background(…)`) because `.background`
    /// does not propagate `.ignoresSafeArea` from the inner view.
    func brickWallBackground() -> some View {
        ZStack(alignment: .top) {
            BrickWallBackground()
            self
        }
    }
}
