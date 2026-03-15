import SwiftUI
import UIKit

/// A UITextView wrapper that renders URLs as tappable blue links.
/// Tapping a link fires `onLinkTapped` instead of opening the system browser.
/// Formatting (bold, italic, font size) is applied via `TextFormatting`.
struct LinkedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var formatting: TextFormatting
    var onLinkTapped: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isEditable = true
        tv.isSelectable = true
        tv.isScrollEnabled = true
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 56, bottom: 40, right: 16)
        tv.typingAttributes = baseAttributes()

        // Load initial content with link highlights
        tv.attributedText = attributedString(for: text)

        // Tap gesture: intercepts taps on link-styled characters
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        tv.addGestureRecognizer(tap)

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Skip while the user is actively typing to avoid disrupting the cursor
        guard !context.coordinator.isEditing else {
            // Still update typing attributes for live formatting changes
            uiView.typingAttributes = baseAttributes()
            return
        }
        if uiView.text != text {
            uiView.attributedText = attributedString(for: text)
        }
        uiView.typingAttributes = baseAttributes()
    }

    // MARK: - Attributed string factory

    static var defaultAttributes: [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.label]
    }

    func baseAttributes() -> [NSAttributedString.Key: Any] {
        [.font: formatting.font, .foregroundColor: UIColor.label]
    }

    func attributedString(for text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttributes())
        guard
            let detector = try? NSDataDetector(
                types: NSTextCheckingResult.CheckingType.link.rawValue
            )
        else { return result }

        let range = NSRange(text.startIndex..., in: text)
        for match in detector.matches(in: text, options: [], range: range) {
            guard let url = match.url else { continue }
            result.addAttributes([
                .link: url,
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: UIColor.systemBlue
            ], range: match.range)
        }
        return result
    }

    static func attributedString(for text: String) -> NSAttributedString {
        LinkedTextEditor(
            text: .constant(text),
            formatting: TextFormatting(),
            onLinkTapped: { _ in }
        ).attributedString(for: text)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: LinkedTextEditor
        var isEditing = false

        init(_ parent: LinkedTextEditor) { self.parent = parent }

        // MARK: UITextViewDelegate

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            textView.typingAttributes = parent.baseAttributes()
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            parent.text = textView.text ?? ""
            // Re-apply link highlighting on the finished text
            let cursorRange = textView.selectedRange
            textView.attributedText = parent.attributedString(for: textView.text ?? "")
            textView.selectedRange = cursorRange
        }

        // MARK: Link tap detection

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = gesture.view as? UITextView else { return }
            if let url = linkURL(at: gesture.location(in: tv), in: tv) {
                gesture.cancelsTouchesInView = true
                parent.onLinkTapped(url)
            }
        }

        private func linkURL(at point: CGPoint, in tv: UITextView) -> URL? {
            let inset = tv.textContainerInset
            let adjusted = CGPoint(x: point.x - inset.left, y: point.y - inset.top)
            let lm = tv.layoutManager
            let tc = tv.textContainer

            var frac: CGFloat = 0
            let glyphIdx = lm.glyphIndex(
                for: adjusted,
                in: tc,
                fractionOfDistanceThroughGlyph: &frac
            )

            // Confirm the tap actually lands inside the glyph rect (not whitespace beyond EOL)
            let glyphRect = lm.boundingRect(
                forGlyphRange: NSRange(location: glyphIdx, length: 1),
                in: tc
            )
            guard glyphRect.contains(adjusted) else { return nil }

            let charIdx = lm.characterIndexForGlyph(at: glyphIdx)
            guard charIdx < tv.textStorage.length else { return nil }

            return tv.textStorage.attributes(at: charIdx, effectiveRange: nil)[.link] as? URL
        }

        // Allow simultaneous gesture recognition with the text view's own recognizers
        func gestureRecognizer(
            _ gr: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }
}
