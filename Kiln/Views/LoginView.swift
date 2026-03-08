import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var apiKey = ""
    @FocusState private var isFieldFocused: Bool

    private var isLoading: Bool { authService.state == .authenticating }
    private var canConnect: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            Spacer()

            // Branding
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignSystem.Colors.primary)

                Text("Kiln")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            // Instruction
            Text("Enter your API key to get started")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Input + Button
            VStack(spacing: DesignSystem.Spacing.md) {
                TextField("API key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                    .cardShadow()
                    .focused($isFieldFocused)

                Button {
                    let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
                    Task {
                        await authService.login(apiKey: trimmed)
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(DesignSystem.Colors.textOnPrimary)
                        }
                        Text(isLoading ? "Connecting..." : "Connect")
                            .font(DesignSystem.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
                    .background(canConnect ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.4))
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
                .disabled(!canConnect)

                // Error message
                if let error = authService.errorMessage {
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.destructive)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
            Spacer()
        }
        .grainedBackground()
        .onTapGesture {
            isFieldFocused = false
        }
    }
}
