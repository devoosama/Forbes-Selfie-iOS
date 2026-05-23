import SwiftUI
import UIKit

// MARK: - Single Digit Box
struct DigitBox: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(digit.isEmpty ? Color(hex: "#111827") : Color(hex: "#0D2A4A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isFocused ? Color(hex: "#0EA5E9") :
                            digit.isEmpty ? Color(hex: "#1A2744") : Color(hex: "#0077B6"),
                            lineWidth: isFocused ? 2 : 1.5
                        )
                )
                .shadow(color: isFocused ? Color(hex: "#0EA5E9").opacity(0.3) : .clear, radius: 8)

            if !digit.isEmpty {
                Text(digit)
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#38BDF8"))
            }
        }
        .frame(width: 62, height: 74)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: digit)
    }
}

// MARK: - Backspace-Aware UITextField
/// A UITextField that fires onDelete when backspace is pressed on an empty field.
struct BackspaceTextField: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var onDelete: () -> Void          // called when backspace pressed on empty
    var onFilled: () -> Void          // called when a digit is entered

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> BackspaceUITextField {
        let tf = BackspaceUITextField()
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.textColor = .clear
        tf.tintColor = .clear
        tf.backgroundColor = .clear
        tf.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        tf.delegate = context.coordinator
        tf.onBackspaceOnEmpty = {
            DispatchQueue.main.async { self.onDelete() }
        }
        return tf
    }

    func updateUIView(_ tf: BackspaceUITextField, context: Context) {
        // Sync text
        if tf.text != text { tf.text = text }
        // Manage focus
        if isFocused && !tf.isFirstResponder {
            tf.becomeFirstResponder()
        } else if !isFocused && tf.isFirstResponder {
            tf.resignFirstResponder()
        }
    }

    // MARK: Coordinator
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BackspaceTextField
        init(_ p: BackspaceTextField) { self.parent = p }

        func textField(_ tf: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = tf.text ?? ""

            if string.isEmpty {
                // Backspace: field will become empty
                if current.isEmpty {
                    parent.onDelete()
                    return false
                }
                DispatchQueue.main.async { self.parent.text = "" }
                return true
            }

            // Accept only digits
            let digits = string.filter { $0.isNumber }
            guard !digits.isEmpty else { return false }

            // Handle paste of full code
            if digits.count >= 4 {
                return false // handled by SwiftUI onChange in OTPInputView
            }

            // Take only last digit
            let newChar = String(digits.last!)
            DispatchQueue.main.async {
                self.parent.text = newChar
                self.parent.onFilled()
            }
            return false  // we manage text ourselves
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {}
        func textFieldDidEndEditing(_ textField: UITextField) {}
    }
}

// MARK: - UITextField subclass that detects backspace on empty
class BackspaceUITextField: UITextField {
    var onBackspaceOnEmpty: (() -> Void)?

    override func deleteBackward() {
        let wasEmpty = (text ?? "").isEmpty
        super.deleteBackward()
        if wasEmpty { onBackspaceOnEmpty?() }
    }
}

// MARK: - OTP Input View
struct OTPInputView: View {
    @Binding var code: [String]
    @Binding var focusedField: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                ZStack {
                    // Visual box
                    DigitBox(digit: code[i], isFocused: focusedField == i)

                    // Invisible but tappable UITextField for input
                    BackspaceTextField(
                        text: $code[i],
                        isFocused: focusedField == i,
                        onDelete: {
                            if i > 0 {
                                code[i] = ""
                                focusedField = i - 1
                            }
                        },
                        onFilled: {
                            if i < 3 { focusedField = i + 1 }
                        }
                    )
                    .frame(width: 62, height: 74)
                    .onChange(of: code[i]) { newVal in
                        let digits = newVal.filter(\.isNumber)
                        // Handle paste of full 4-digit code
                        if digits.count >= 4 {
                            let arr = Array(digits.prefix(4))
                            for j in 0..<4 { code[j] = String(arr[j]) }
                            focusedField = 3
                            return
                        }
                        // Single digit handled by BackspaceTextField coordinator
                    }
                }
                .onTapGesture { focusedField = i }
            }
        }
    }
}
