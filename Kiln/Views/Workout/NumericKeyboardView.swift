import SwiftUI

struct NumericKeyboardConfig {
    var showDecimalKey: Bool = true
    var incrementStep: Double = 1.0
}

enum NumericKey {
    case digit(Int)
    case decimal
    case backspace
}

struct NumericKeyboardView: View {
    let config: NumericKeyboardConfig
    var onKeyTap: (NumericKey) -> Void
    var onDismiss: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void

    private let keyHeight: CGFloat = 52
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignSystem.Colors.hair)
                .frame(height: 1)

            HStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    numpadRow(keys: [1, 2, 3])
                    numpadRow(keys: [4, 5, 6])
                    numpadRow(keys: [7, 8, 9])
                    bottomRow
                }

                VStack(spacing: spacing) {
                    incrementButton
                    decrementButton
                    dismissButton
                }
                .frame(width: 80)
            }
            .padding(spacing)
            .background(DesignSystem.Colors.bgDeeper)
        }
        .frame(height: 260)
    }

    // MARK: - Numpad Rows

    private func numpadRow(keys: [Int]) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { digit in
                digitKey(label: "\(digit)") {
                    onKeyTap(.digit(digit))
                }
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: spacing) {
            if config.showDecimalKey {
                digitKey(label: ".") {
                    onKeyTap(.decimal)
                }
            } else {
                Color.clear.frame(height: keyHeight)
            }
            digitKey(label: "0") {
                onKeyTap(.digit(0))
            }
            iconKey(systemImage: "delete.left") {
                onKeyTap(.backspace)
            }
        }
    }

    // MARK: - Action Buttons

    private var dismissButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDismiss()
        } label: {
            Text("Done")
                .font(DesignSystem.Typography.button)
                .foregroundStyle(DesignSystem.Colors.brickText)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(BrickButtonBackground(cornerRadius: DesignSystem.CornerRadius.button))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                .mortarShadow()
        }
    }

    private var decrementButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDecrement()
        } label: {
            HStack(spacing: 4) {
                Text("−")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.ink)
                Text("Less")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(DesignSystem.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var incrementButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onIncrement()
        } label: {
            HStack(spacing: 4) {
                Text("+")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.ink)
                Text("More")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(DesignSystem.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Key Button Helpers

    private func digitKey(label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(DesignSystem.Typography.mono(22, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(DesignSystem.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func iconKey(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(DesignSystem.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignSystem.Colors.cardEdge, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
