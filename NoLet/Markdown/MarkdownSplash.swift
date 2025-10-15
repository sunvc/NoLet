
import MarkdownUI
import SwiftUI
import Splash


struct CodeBlock: View {
    var configuration: CodeBlockConfiguration
    
    init(_ configuration: CodeBlockConfiguration) {
        self.configuration = configuration
    }
    
    var language: String {
        configuration.language ?? "code"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    Clipboard.set(configuration.content)
                    Haptic.impact()
                    Toast.copy(title: "复制成功")
                }) {
                    Image(systemName: "doc.on.doc")
                        .padding(7)
                }
                .buttonStyle(GrowingButton())
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(MarkdownColors.secondaryBackground)
            
            Divider()
            
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(16)
            }
        }
        .background(MarkdownColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .markdownMargin(top: .zero, bottom: .em(0.8))
    }
}

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
    
    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }
    
    func highlightCode(_ content: String, language: String?) -> Text {
        guard language != nil else {
            return Text(content)
        }
        
        return self.syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}

struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme
    
    init(theme: Splash.Theme) {
        self.theme = theme
    }
    
    func makeBuilder() -> Builder {
        Builder(theme: self.theme)
    }
}

extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text]
        
        fileprivate init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }
        
        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
            self.accumulatedText.append(Text(token).foregroundColor(.init(color)))
        }
        
        mutating func addPlainText(_ text: String) {
            self.accumulatedText.append(
                Text(text).foregroundColor(.init(self.theme.plainTextColor))
            )
        }
        
        mutating func addWhitespace(_ whitespace: String) {
            self.accumulatedText.append(Text(whitespace))
        }
        
        func build() -> Text {
            self.accumulatedText.reduce(Text(verbatim: ""), +)
        }
    }
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


