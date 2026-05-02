import SwiftUI
import UIKit

struct CustomInputTextField: UIViewRepresentable {
    @Binding var value: Double?
    let placeholder: String
    let config: NumericKeyboardConfig
    var onValueChanged: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, config: config, onValueChanged: onValueChanged)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.textAlignment = .center
        textField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .bold)
        textField.textColor = UIColor(DesignSystem.Colors.ink)
        textField.delegate = context.coordinator
        textField.tintColor = UIColor(DesignSystem.Colors.brick1)
        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let hostingController = makeKeyboardHostingController(for: textField, coordinator: context.coordinator)
        textField.inputView = hostingController.view

        context.coordinator.hostingController = hostingController

        // Sync initial value
        if let v = value {
            textField.text = context.coordinator.format(v)
        }

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Only sync from binding when not actively editing
        guard !textField.isFirstResponder else { return }
        if let v = value {
            textField.text = context.coordinator.format(v)
        } else {
            textField.text = nil
        }

        // Rebuild inputView if config changed
        if context.coordinator.config.incrementStep != config.incrementStep ||
           context.coordinator.config.showDecimalKey != config.showDecimalKey {
            context.coordinator.config = config
            let hc = makeKeyboardHostingController(for: textField, coordinator: context.coordinator)
            textField.inputView = hc.view
            context.coordinator.hostingController = hc
        }
    }

    private func makeKeyboardHostingController(
        for textField: UITextField,
        coordinator: Coordinator
    ) -> UIHostingController<NumericKeyboardView> {
        let keyboardView = NumericKeyboardView(
            config: config,
            onKeyTap: { [weak textField] key in
                guard let textField else { return }
                coordinator.handleKey(key, in: textField)
            },
            onDismiss: { [weak textField] in
                textField?.resignFirstResponder()
            },
            onIncrement: { [weak textField] in
                guard let textField else { return }
                coordinator.increment(in: textField)
            },
            onDecrement: { [weak textField] in
                guard let textField else { return }
                coordinator.decrement(in: textField)
            }
        )

        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 260)
        hostingController.view.autoresizingMask = [.flexibleWidth]
        return hostingController
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextFieldDelegate {
        var value: Binding<Double?>
        var config: NumericKeyboardConfig
        var onValueChanged: (() -> Void)?
        var hostingController: UIHostingController<NumericKeyboardView>?
        var pendingReplace = true

        init(value: Binding<Double?>, config: NumericKeyboardConfig, onValueChanged: (() -> Void)? = nil) {
            self.value = value
            self.config = config
            self.onValueChanged = onValueChanged
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            pendingReplace = true
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func format(_ v: Double) -> String {
            if !config.showDecimalKey {
                // Integer mode
                return "\(Int(v))"
            }
            if v == v.rounded() && v >= 0 {
                return "\(Int(v))"
            }
            return String(format: "%.1f", v)
        }

        func handleKey(_ key: NumericKey, in textField: UITextField) {
            var text = textField.text ?? ""
            switch key {
            case .digit(let d):
                if pendingReplace {
                    text = "\(d)"
                    pendingReplace = false
                } else {
                    text.append("\(d)")
                }
            case .decimal:
                guard config.showDecimalKey else { return }
                if pendingReplace {
                    text = "0."
                    pendingReplace = false
                } else if !text.contains(".") {
                    if text.isEmpty { text = "0" }
                    text.append(".")
                }
            case .backspace:
                pendingReplace = false
                if !text.isEmpty {
                    text.removeLast()
                }
            }
            textField.text = text
            syncValue(from: text)
        }

        func increment(in textField: UITextField) {
            let current = value.wrappedValue ?? 0
            let newVal = current + config.incrementStep
            value.wrappedValue = newVal
            textField.text = format(newVal)
            pendingReplace = true
            onValueChanged?()
        }

        func decrement(in textField: UITextField) {
            let current = value.wrappedValue ?? 0
            let newVal = max(0, current - config.incrementStep)
            value.wrappedValue = newVal
            textField.text = format(newVal)
            pendingReplace = true
            onValueChanged?()
        }

        private func syncValue(from text: String) {
            if text.isEmpty {
                value.wrappedValue = nil
            } else if let parsed = Double(text) {
                value.wrappedValue = parsed
            }
            onValueChanged?()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // Final sync on dismiss
            let text = textField.text ?? ""
            syncValue(from: text)
            // Reformat display
            if let v = value.wrappedValue {
                textField.text = format(v)
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Block direct typing — all input goes through custom keyboard
            return false
        }
    }
}

// MARK: - Convenience Wrappers

struct NumericInputField: View {
    @Binding var value: Double?
    let placeholder: String
    var incrementStep: Double = 1.0
    var onValueChanged: (() -> Void)? = nil

    var body: some View {
        CustomInputTextField(
            value: $value,
            placeholder: placeholder,
            config: NumericKeyboardConfig(
                showDecimalKey: true,
                incrementStep: incrementStep
            ),
            onValueChanged: onValueChanged
        )
        .frame(width: 56, height: 30)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignSystem.Colors.ink)
                .frame(height: 1.5)
        }
    }
}

struct IntInputField: View {
    @Binding var value: Int?
    let placeholder: String
    var incrementStep: Double = 1.0
    var onValueChanged: (() -> Void)? = nil

    private var doubleBinding: Binding<Double?> {
        Binding<Double?>(
            get: { value.map { Double($0) } },
            set: { newVal in value = newVal.map { Int($0) } }
        )
    }

    var body: some View {
        CustomInputTextField(
            value: doubleBinding,
            placeholder: placeholder,
            config: NumericKeyboardConfig(
                showDecimalKey: false,
                incrementStep: incrementStep
            ),
            onValueChanged: onValueChanged
        )
        .frame(width: 56, height: 30)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignSystem.Colors.ink)
                .frame(height: 1.5)
        }
    }
}
