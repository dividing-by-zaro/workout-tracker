import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var apiKey = ""
    @FocusState private var isFieldFocused: Bool

    private var isLoading: Bool { authService.state == .authenticating }
    private var canConnect: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Branding
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    BrickFill(cornerRadius: 6)
                        .frame(width: 96, height: 42)
                        .mortarShadow()
                    Text("K")
                        .font(DesignSystem.Typography.display(32))
                        .foregroundStyle(DesignSystem.Colors.brickText)
                }

                Text("Kiln")
                    .font(DesignSystem.Typography.display(56))
                    .foregroundStyle(DesignSystem.Colors.ink)
            }

            // Tagline (metaphor)
            Text("You're firing yourself in the kiln and becoming hard as a brick.")
                .font(DesignSystem.Typography.serifItalic(14))
                .foregroundStyle(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Input + Button
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Enter your API key to begin.")
                    .font(DesignSystem.Typography.helper)
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                TextField("API key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(DesignSystem.Typography.mono(14, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.ink)
                    .tint(DesignSystem.Colors.brick1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(DesignSystem.Colors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
                    )
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
                                .tint(DesignSystem.Colors.brickText)
                        }
                        Text(isLoading ? "Connecting..." : "Connect")
                            .font(DesignSystem.Typography.buttonLarge)
                            .foregroundStyle(DesignSystem.Colors.brickText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        BrickButtonBackground(cornerRadius: DesignSystem.CornerRadius.button)
                    )
                    .opacity(canConnect ? 1 : 0.5)
                    .mortarShadow()
                }
                .buttonStyle(.plain)
                .disabled(!canConnect)

                // Error message
                if let error = authService.errorMessage {
                    Text(error)
                        .font(DesignSystem.Typography.helper)
                        .foregroundStyle(DesignSystem.Colors.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
            Spacer()
        }
        .brickWallBackground()
        .onTapGesture {
            isFieldFocused = false
        }
    }
}
