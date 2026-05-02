import SwiftUI

/// Italic, journal-feel note. The italic typography itself is the affordance —
/// no leading icons, no pencils, no buttons. Tap anywhere on the text to edit.
///
/// Empty state shows the placeholder italic in `ink3`; written notes render in `ink2`.
struct NotesSection: View {
    let title: String
    let placeholder: String
    @Binding var notes: String?
    var onSave: (() -> Void)? = nil

    /// Visual variants. `.standalone` renders the placeholder/text on its own line
    /// (the workout-header use). `.inlineSuffix` is a no-frills `Text` that the
    /// caller can drop next to a subtitle separated by a middle-dot.
    enum Style {
        case standalone
        case inlineSuffix
    }

    var style: Style = .standalone

    @State private var showEditor = false

    private var displayText: String? {
        guard let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    var body: some View {
        Button {
            showEditor = true
        } label: {
            content
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            NotesEditorSheet(title: title, notes: $notes, onSave: onSave)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .standalone:
            if let text = displayText {
                Text(text)
                    .font(DesignSystem.Typography.serifItalic(14))
                    .foregroundStyle(DesignSystem.Colors.ink2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1.4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(placeholder)
                    .font(DesignSystem.Typography.serifItalic(14))
                    .foregroundStyle(DesignSystem.Colors.ink3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .inlineSuffix:
            Text(displayText ?? placeholder)
                .font(DesignSystem.Typography.serifItalic(12))
                .foregroundStyle(displayText == nil ? DesignSystem.Colors.ink3 : DesignSystem.Colors.ink2)
                .lineLimit(1)
        }
    }
}

struct NotesEditorSheet: View {
    let title: String
    @Binding var notes: String?
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            TextEditor(text: $draft)
                .font(DesignSystem.Typography.serifItalic(15))
                .foregroundStyle(DesignSystem.Colors.ink)
                .scrollContentBackground(.hidden)
                .padding(DesignSystem.Spacing.sm)
                .focused($isFocused)
                .background(DesignSystem.Colors.card)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .font(DesignSystem.Typography.button)
                            .foregroundStyle(DesignSystem.Colors.ink2)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            notes = trimmed.isEmpty ? nil : trimmed
                            onSave?()
                            dismiss()
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.brick2)
                    }
                }
                .onAppear {
                    draft = notes ?? ""
                    isFocused = true
                }
        }
        .presentationDetents([.medium, .large])
    }
}
