import SwiftUI

struct SwipeToDelete<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var showingDelete = false

    private let deleteWidth: CGFloat = 70

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind the content
            if showingDelete || offset < 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        offset = 0
                        showingDelete = false
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: deleteWidth)
                        .frame(maxHeight: .infinity)
                        .background(DesignSystem.Colors.destructive)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Main content
            content()
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            let translation = value.translation
                            // Only activate if gesture is predominantly horizontal
                            guard abs(translation.width) > abs(translation.height) * 1.5 else { return }
                            if translation.width < 0 {
                                // Swiping left — rubber band at deleteWidth
                                offset = max(translation.width, -deleteWidth * 1.2)
                            } else if showingDelete {
                                // Swiping right to dismiss
                                offset = min(translation.width - deleteWidth, 0)
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation
                            guard abs(translation.width) > abs(translation.height) * 1.5 else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = 0
                                    showingDelete = false
                                }
                                return
                            }
                            withAnimation(.easeOut(duration: 0.2)) {
                                if translation.width < -40 {
                                    offset = -deleteWidth
                                    showingDelete = true
                                } else {
                                    offset = 0
                                    showingDelete = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}
