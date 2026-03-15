import SwiftUI

/// Formatting options that the text editor can apply.
struct TextFormatting {
    var isBold = false
    var isItalic = false
    var fontSize: CGFloat = 16

    var font: UIFont {
        var descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold   { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        if !traits.isEmpty, let updated = descriptor.withSymbolicTraits(traits) {
            descriptor = updated
        }
        return UIFont(descriptor: descriptor, size: fontSize)
    }
}

/// Keyboard-attached toolbar for basic rich-text formatting.
struct FormattingToolbar: View {
    @Binding var formatting: TextFormatting
    var onDismissKeyboard: () -> Void

    private let fontSizes: [CGFloat] = [13, 15, 16, 18, 20, 24]

    var body: some View {
        HStack(spacing: 4) {
            // Bold
            ToolbarToggle(icon: "bold", label: "Bold", isOn: $formatting.isBold)

            // Italic
            ToolbarToggle(icon: "italic", label: "Italic", isOn: $formatting.isItalic)

            Divider().frame(height: 22)

            // Font size decrease
            Button {
                if let idx = fontSizes.firstIndex(of: formatting.fontSize), idx > 0 {
                    formatting.fontSize = fontSizes[idx - 1]
                }
            } label: {
                Image(systemName: "textformat.size.smaller")
                    .frame(width: 32, height: 32)
            }
            .disabled(formatting.fontSize <= fontSizes.first!)

            Text("\(Int(formatting.fontSize))")
                .font(.caption.monospacedDigit())
                .frame(width: 26)

            // Font size increase
            Button {
                if let idx = fontSizes.firstIndex(of: formatting.fontSize), idx < fontSizes.count - 1 {
                    formatting.fontSize = fontSizes[idx + 1]
                }
            } label: {
                Image(systemName: "textformat.size.larger")
                    .frame(width: 32, height: 32)
            }
            .disabled(formatting.fontSize >= fontSizes.last!)

            Spacer()

            // Dismiss keyboard
            Button(action: onDismissKeyboard) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.bar)
    }
}

private struct ToolbarToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: icon)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOn ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .foregroundStyle(isOn ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel(label)
    }
}
