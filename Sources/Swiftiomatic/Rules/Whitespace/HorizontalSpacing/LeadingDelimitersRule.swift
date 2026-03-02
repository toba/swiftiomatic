import SwiftSyntax

struct LeadingDelimitersRule {
    static let id = "leading_delimiters"
    static let name = "Leading Delimiters"
    static let summary = "Delimiters should not appear at the start of a line; move them to the end of the previous line"
    static let scope: Scope = .format
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = maybeFoo,
                      let bar = maybeBar else { return }
                """)
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = maybeFoo
                      ↓, let bar = maybeBar else { return }
                """)
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension LeadingDelimitersRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LeadingDelimitersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      guard token.tokenKind == .comma || token.tokenKind == .semicolon else {
        return .visitChildren
      }

      // Check if this delimiter is at the start of a line (preceded only by whitespace after a linebreak)
      let leading = token.leadingTrivia
      var foundNewline = false
      for piece in leading {
        switch piece {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
          foundNewline = true
        case .spaces, .tabs:
          break  // whitespace is OK between newline and token
        default:
          foundNewline = false  // comment or other content — not start of line
        }
      }

      if foundNewline {
        violations.append(token.positionAfterSkippingLeadingTrivia)
      }
      return .visitChildren
    }
  }
}
