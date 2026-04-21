import SwiftUI

struct NotesSection: View {
    let title: String
    let placeholder: String
    @Binding var notes: String?
    var onSave: (() -> Void)? = nil
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
            if let text = displayText {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.top, 2)
                    Text(text)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .italic()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 11))
                    Text(placeholder)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            NotesEditorSheet(title: title, notes: $notes, onSave: onSave)
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
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(DesignSystem.Spacing.sm)
                .focused($isFocused)
                .background(DesignSystem.Colors.surface)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            notes = trimmed.isEmpty ? nil : trimmed
                            onSave?()
                            dismiss()
                        }
                        .fontWeight(.semibold)
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
