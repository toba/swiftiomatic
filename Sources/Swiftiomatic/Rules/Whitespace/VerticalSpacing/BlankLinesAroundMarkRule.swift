import Foundation
import SwiftSyntax

struct BlankLinesAroundMarkRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "blank_lines_around_mark",
    name: "Blank Lines Around MARK",
    description: "MARK comments should be preceded and followed by a blank line",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        func foo() {}

        // MARK: - Bar

        func bar() {}
        """)
    ],
    triggeringExamples: [
      Example(
        """
        func foo() {}
        ↓// MARK: - Bar
        func bar() {}
        """)
    ],
  )
}

extension BlankLinesAroundMarkRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension BlankLinesAroundMarkRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      let leading = token.leadingTrivia
      var position = token.position
      var newlineCountBeforeMark = 0
      for (index, piece) in leading.enumerated() {
        switch piece {
        case .lineComment(let text):
          if isMarkComment(text) {
            // Check blank line before MARK
            if newlineCountBeforeMark < 2,
              token.previousToken(viewMode: .sourceAccurate) != nil
            {
              // Need at least 2 newlines before MARK (blank line)
              // But skip if this is at the start of a scope
              if !isAtStartOfScope(token) {
                violations.append(position)
              }
            }

            // Check blank line after MARK
            let remainingTrivia = Trivia(pieces: Array(leading.dropFirst(index + 1)))
            if remainingTrivia.newlineCount < 2,
              token.nextToken(viewMode: .sourceAccurate) != nil
            {
              violations.append(
                position.advanced(by: piece.sourceLength.utf8Length))
            }
          }
          newlineCountBeforeMark = 0
        case .newlines(let count):
          newlineCountBeforeMark += count
        case .carriageReturns(let count), .carriageReturnLineFeeds(let count):
          newlineCountBeforeMark += count
        case .spaces, .tabs:
          break
        default:
          newlineCountBeforeMark = 0
        }
        position = position.advanced(by: piece.sourceLength.utf8Length)
      }
      return .visitChildren
    }

    private func isMarkComment(_ text: String) -> Bool {
      let trimmed = text.dropFirst(2).trimmingCharacters(in: .whitespaces)
      return trimmed.hasPrefix("MARK:")
    }

    private func isAtStartOfScope(_ token: TokenSyntax) -> Bool {
      guard let prevToken = token.previousToken(viewMode: .sourceAccurate) else {
        return true  // Start of file
      }
      return prevToken.tokenKind == .leftBrace
    }
  }
}
