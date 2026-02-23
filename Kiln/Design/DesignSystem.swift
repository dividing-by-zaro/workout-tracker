import SwiftUI

enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        static let primary = Color(red: 0.92, green: 0.26, blue: 0.24)       // Red accent color
        static let background = Color(red: 0.07, green: 0.07, blue: 0.08)    // Near-black background
        static let surface = Color(red: 0.14, green: 0.14, blue: 0.16)       // Elevated surface
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.6)
        static let success = Color(red: 0.30, green: 0.78, blue: 0.40)       // Green for completed set
        static let timerActive = Color(red: 0.92, green: 0.26, blue: 0.24)   // Red-ish active timer
        static let timerBackground = Color(red: 0.20, green: 0.10, blue: 0.10)
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
