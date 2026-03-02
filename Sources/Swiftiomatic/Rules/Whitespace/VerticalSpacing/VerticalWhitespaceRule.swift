import Foundation
import SwiftSyntax

struct VerticalWhitespaceRule {
    static let id = "vertical_whitespace"
    static let name = "Vertical Whitespace"
    static let summary = "Limit vertical whitespace to a single empty line"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let abc = 0\n"),
              Example("let abc = 0\n\n"),
              Example("/* bcs \n\n\n\n*/"),
              Example("// bca \n\n"),
              Example("class CCCC {\n  \n}"),
              Example(
                """
                // comment

                import Foundation
                """,
              ),
              Example(
                """

                // comment

                import Foundation
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let aaaa = 0\n\n\n"),
              Example("struct AAAA {}\n\n\n\n"),
              Example("class BBBB {}\n\n\n"),
              Example("class CCCC {\n  \n  \n}"),
              Example(
                """


                import Foundation
                """,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("let b = 0\n\n\nclass AAA {}\n"): Example("let b = 0\n\nclass AAA {}\n"),
              Example("let c = 0\n\n\nlet num = 1\n"): Example("let c = 0\n\nlet num = 1\n"),
              Example("// bca \n\n\n"): Example("// bca \n\n"),
              Example("class CCCC {\n  \n  \n  \n}"): Example("class CCCC {\n  \n}"),
            ]
    }
  var options = VerticalWhitespaceOptions()

}

extension VerticalWhitespaceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension VerticalWhitespaceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    /// The number of additional newlines to expect before the first token.
    private var firstTokenAdditionalNewlines = 1

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      // Reset immediately. Only the first token has an additional leading newline.
      defer { firstTokenAdditionalNewlines = 0 }

      // The strategy here is to keep track of the position of the _first_ violating newline
      // in each consecutive run, and report the violation when the run _ends_.

      if token.leadingTrivia.isEmpty {
        return .visitChildren
      }

      var consecutiveNewlines = 0
      var currentPosition = token.position
      var violationPosition: AbsolutePosition?

      func process(_ count: Int, _ offset: Int) {
        for _ in 0..<(count + firstTokenAdditionalNewlines) {
          if consecutiveNewlines > configuration.maxEmptyLines, violationPosition == nil {
            violationPosition = currentPosition
          }
          consecutiveNewlines += 1
          currentPosition = currentPosition.advanced(by: offset)
        }
      }

      for piece in token.leadingTrivia {
        switch piece {
        case .newlines(let count), .carriageReturns(let count), .formfeeds(let count),
          .verticalTabs(let count):
          process(count, 1)
        case .carriageReturnLineFeeds(let count):
          process(count, 2)  // CRLF is 2 bytes
        case .spaces, .tabs:
          currentPosition += piece.sourceLength
        default:
          // A comment breaks the chain of newlines.
          firstTokenAdditionalNewlines = 0
          if let violationPosition {
            report(violationPosition, consecutiveNewlines)
          }
          violationPosition = nil
          consecutiveNewlines = 0
          currentPosition += piece.sourceLength
        }
      }
      if let violationPosition {
        report(violationPosition, consecutiveNewlines)
      }

      return .visitChildren
    }

    private func report(_ position: AbsolutePosition, _ newlines: Int) {
      violations.append(
        SyntaxViolation(
          position: position,
          reason: configuration
            .configuredDescriptionReason + "; currently \(newlines - 1)",
        ),
      )
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      var result = [TriviaPiece]()
      var pendingWhitespace = [TriviaPiece]()
      var consecutiveNewlines = 0

      func process(_ count: Int, _ create: (Int) -> TriviaPiece) {
        let linesToPreserve = min(
          count, max(0, configuration.maxEmptyLines + 1 - consecutiveNewlines),
        )
        consecutiveNewlines += count

        if count > linesToPreserve {
          numberOfCorrections += count - linesToPreserve
        }

        if linesToPreserve > 0 {
          // We can still add this piece, even if we adjusted its count lower.
          // Pull in any pending whitespace along with it.
          result.append(contentsOf: pendingWhitespace)
          result.append(create(linesToPreserve))
          pendingWhitespace.removeAll()
        } else {
          // We're now in violation. Dump pending whitespace so it's excluded from the result.
          pendingWhitespace.removeAll()
        }
      }

      for piece in token.leadingTrivia {
        switch piece {
        case .newlines(let count):
          process(count, TriviaPiece.newlines)
        case .carriageReturns(let count):
          process(count, TriviaPiece.carriageReturns)
        case .carriageReturnLineFeeds(let count):
          process(count, TriviaPiece.carriageReturnLineFeeds)
        case .formfeeds(let count):
          process(count, TriviaPiece.formfeeds)
        case .verticalTabs(let count):
          process(count, TriviaPiece.verticalTabs)
        case .spaces, .tabs:
          pendingWhitespace.append(piece)
        default:
          // Reset and pull in pending whitespace
          consecutiveNewlines = 0
          result.append(contentsOf: pendingWhitespace)
          result.append(piece)
          pendingWhitespace.removeAll()
        }
      }
      // Pull in any remaining pending whitespace
      if !pendingWhitespace.isEmpty {
        result.append(contentsOf: pendingWhitespace)
      }

      return super.visit(token.with(\.leadingTrivia, Trivia(pieces: result)))
    }
  }
}
