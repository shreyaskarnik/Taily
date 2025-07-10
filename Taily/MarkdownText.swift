import SwiftUI

struct MarkdownText: View {
    let content: String
    let font: Font
    let lineSpacing: CGFloat
    let highlightRange: NSRange?
    
    init(_ content: String, font: Font = .body, lineSpacing: CGFloat = 6, highlightRange: NSRange? = nil) {
        self.content = content
        self.font = font
        self.lineSpacing = lineSpacing
        self.highlightRange = highlightRange
    }
    
    var body: some View {
        Text(parseMarkdownAndHighlight(content))
            .font(font)
            .lineSpacing(lineSpacing)
    }
    
    private func parseMarkdownAndHighlight(_ text: String) -> AttributedString {
        // First parse markdown
        var attributedString = parseMarkdown(text)
        
        // Then apply speech highlighting if provided
        if let highlightRange = highlightRange,
           let stringRange = Range(highlightRange, in: text),
           let attributedRange = Range(stringRange, in: attributedString) {
            
            attributedString[attributedRange].backgroundColor = Color.yellow.opacity(0.3)
            attributedString[attributedRange].foregroundColor = Color.primary
        }
        
        return attributedString
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Parse **bold** formatting
        let boldPattern = #"\*\*(.*?)\*\*"#
        let regex = try! NSRegularExpression(pattern: boldPattern)
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        // Process matches in reverse order to maintain correct indices
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            // Get the content without the ** markers
            let boldContent = nsString.substring(with: contentRange)
            
            // Convert NSRange to AttributedString range
            let stringRange = Range(fullRange, in: text)
            if let stringRange = stringRange,
               let attributedRange = Range(stringRange, in: attributedString) {
                
                // Replace the **text** with just the text and make it bold
                var boldText = AttributedString(boldContent)
                boldText.font = .body.bold()
                boldText.foregroundColor = .primary
                
                attributedString.replaceSubrange(attributedRange, with: boldText)
            }
        }
        
        return attributedString
    }
}


#Preview {
    VStack(alignment: .leading, spacing: 20) {
        MarkdownText("Once upon a time, there lived a brave little girl named **Tilly**.")
        
        MarkdownText("She had a fluffy Shiba Inu named **Sparky** who loved to explore.")
        
        MarkdownText("They met a friendly **Fairy Tale** character who gifted them a glowing acorn.")
        
        MarkdownText("Along the way, they helped a **Pirate** and a **Superhero** retrieve a lost star.")
    }
    .padding()
}