import SwiftUI

struct RestTimerView: View {
    let restTimer: RestTimerService
    var onAdjust: ((Int) -> Void)?

    var body: some View {
        if restTimer.isRunning {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.timerBackground, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: restTimer.progress)
                        .stroke(DesignSystem.Colors.timerActive, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: restTimer.progress)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("Rest Timer")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(formatTime(restTimer.remainingSeconds))
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .monospacedDigit()
                }

                Spacer()

                Button("Skip") {
                    restTimer.stop()
                }
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.timerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                onAdjust?(restTimer.totalSeconds)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
