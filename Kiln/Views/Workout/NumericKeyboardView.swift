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
    private let spacing: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: spacing) {
                // Left 3-column numpad
                VStack(spacing: spacing) {
                    numpadRow(keys: [1, 2, 3])
                    numpadRow(keys: [4, 5, 6])
                    numpadRow(keys: [7, 8, 9])
                    bottomRow
                }

                // Right action column
                VStack(spacing: spacing) {
                    dismissButton
                    decrementButton
                    incrementButton
                }
                .frame(width: 80)
            }
            .background(Color(red: 0.82, green: 0.79, blue: 0.76))
        }
        .frame(height: 260)
    }

    // MARK: - Numpad Rows

    private func numpadRow(keys: [Int]) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { digit in
                keyButton(label: "\(digit)") {
                    onKeyTap(.digit(digit))
                }
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: spacing) {
            if config.showDecimalKey {
                keyButton(label: ".") {
                    onKeyTap(.decimal)
                }
            } else {
                Color(red: 0.90, green: 0.87, blue: 0.84)
                    .frame(height: keyHeight)
            }
            keyButton(label: "0") {
                onKeyTap(.digit(0))
            }
            keyButton(systemImage: "delete.left.fill") {
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
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(Color(red: 0.90, green: 0.87, blue: 0.84))
        }
    }

    private var decrementButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDecrement()
        } label: {
            Text("−")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight * 1.5 + spacing * 0.5)
                .background(DesignSystem.Colors.primary)
        }
    }

    private var incrementButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onIncrement()
        } label: {
            Text("+")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight * 1.5 + spacing * 0.5)
                .background(DesignSystem.Colors.primary)
        }
    }

    // MARK: - Key Button Helpers

    private func keyButton(label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(Color.white)
        }
    }

    private func keyButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(Color.white)
        }
    }
}
