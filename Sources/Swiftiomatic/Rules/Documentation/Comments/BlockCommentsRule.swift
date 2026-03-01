import SwiftSyntax

struct BlockCommentsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "block_comments",
    name: "Block Comments",
    description: "Block comments (`/* */`) should be converted to line comments (`//`)",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        // A comment
        // on multiple lines
        """,
      ),
      Example(
        """
        /// A doc comment
        func foo() {}
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓/* A comment
           on multiple lines */
        """,
      )
    ],
  )
}

extension BlockCommentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension BlockCommentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
      checkTrivia(node.leadingTrivia, at: node.position)
      return .visitChildren
    }

    private func checkTrivia(_ trivia: Trivia, at basePosition: AbsolutePosition) {
      var offset = basePosition
      for piece in trivia {
        switch piece {
        case .blockComment:
          violations.append(offset)
        default:
          break
        }
        offset = offset.advanced(by: piece.sourceLength.utf8Length)
      }
    }
  }
}
