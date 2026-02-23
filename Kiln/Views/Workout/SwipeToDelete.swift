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
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                // Swiping left — rubber band at deleteWidth
                                offset = max(translation, -deleteWidth * 1.2)
                            } else if showingDelete {
                                // Swiping right to dismiss
                                offset = min(translation - deleteWidth, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if value.translation.width < -40 {
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
