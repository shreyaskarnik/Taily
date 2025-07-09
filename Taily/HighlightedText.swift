import SwiftUI
import Foundation

struct HighlightedText: View {
    let text: String
    let highlightRange: NSRange?
    let font: Font
    let lineSpacing: CGFloat
    let highlightColor: Color
    
    init(
        text: String,
        highlightRange: NSRange? = nil,
        font: Font = .body,
        lineSpacing: CGFloat = 6,
        highlightColor: Color = .yellow.opacity(0.3)
    ) {
        self.text = text
        self.highlightRange = highlightRange
        self.font = font
        self.lineSpacing = lineSpacing
        self.highlightColor = highlightColor
    }
    
    var body: some View {
        if let range = highlightRange, range.location < text.count {
            let attributedString = createAttributedString()
            Text(AttributedString(attributedString))
                .font(font)
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(font)
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        }
    }
    
    private func createAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Set default attributes
        let fullRange = NSRange(location: 0, length: text.count)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        
        // Add highlight for current word/phrase being spoken
        if let range = highlightRange {
            let safeRange = NSRange(
                location: min(range.location, text.count),
                length: min(range.length, text.count - range.location)
            )
            
            if safeRange.location >= 0 && safeRange.location < text.count && safeRange.length > 0 {
                // Add background color highlight
                attributedString.addAttribute(.backgroundColor, value: UIColor(highlightColor), range: safeRange)
                // Make the text slightly bolder during speech
                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 17, weight: .medium), range: safeRange)
            }
        }
        
        return attributedString
    }
}

struct HighlightedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HighlightedText(
                text: "Once upon a time, in a magical forest, there lived a brave little fox named Luna who loved to explore.",
                highlightRange: NSRange(location: 17, length: 16),
                font: .body
            )
            .padding()
            
            HighlightedText(
                text: "This is a story without highlighting.",
                highlightRange: nil,
                font: .body
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}