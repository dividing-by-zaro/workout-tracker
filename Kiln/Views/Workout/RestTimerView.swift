import SwiftUI

struct RestTimerView: View {
    let restTimer: RestTimerService
    var onSkip: (() -> Void)? = nil

    var body: some View {
        if restTimer.isRunning {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.brick1.opacity(0.2), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: restTimer.progress)
                        .stroke(
                            DesignSystem.Colors.brick1,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: restTimer.progress)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text("COOLING")
                        .font(DesignSystem.Typography.sectionLabel)
                        .tracking(1.4)
                        .foregroundStyle(DesignSystem.Colors.brick2)
                    Text(formatTime(restTimer.remainingSeconds))
                        .font(DesignSystem.Typography.restTimer)
                        .tracking(-0.4)
                        .foregroundStyle(DesignSystem.Colors.ink)
                        .monospacedDigit()
                        .lineSpacing(0)
                }

                Spacer()

                Button {
                    if let onSkip {
                        onSkip()
                    } else {
                        restTimer.stop()
                    }
                } label: {
                    Text("Skip")
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.mortar)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.brick)
                    .stroke(DesignSystem.Colors.brick1.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.brick))
            .padding(.horizontal, DesignSystem.Spacing.brickInset)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
