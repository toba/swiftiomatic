import SwiftSyntax

struct LinebreaksRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LinebreaksConfiguration()
}

extension LinebreaksRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension LinebreaksRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      checkTrivia(token.leadingTrivia, startPosition: token.position)
      checkTrivia(token.trailingTrivia, startPosition: token.endPositionBeforeTrailingTrivia)
      return .visitChildren
    }

    private func checkTrivia(_ trivia: Trivia, startPosition: AbsolutePosition) {
      var position = startPosition
      for piece in trivia {
        switch piece {
        case .carriageReturns, .carriageReturnLineFeeds:
          violations.append(position)
        default:
          break
        }
        position = position.advanced(by: piece.sourceLength.utf8Length)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      let newLeading = normalizeLinebreaks(token.leadingTrivia)
      let newTrailing = normalizeLinebreaks(token.trailingTrivia)
      if newLeading != token.leadingTrivia || newTrailing != token.trailingTrivia {
        numberOfCorrections += 1
        return super.visit(
          token.with(\.leadingTrivia, newLeading).with(\.trailingTrivia, newTrailing))
      }
      return super.visit(token)
    }

    private func normalizeLinebreaks(_ trivia: Trivia) -> Trivia {
      var pieces = [TriviaPiece]()
      var changed = false
      for piece in trivia {
        switch piece {
        case .carriageReturns(let count):
          pieces.append(.newlines(count))
          changed = true
        case .carriageReturnLineFeeds(let count):
          pieces.append(.newlines(count))
          changed = true
        default:
          pieces.append(piece)
        }
      }
      return changed ? Trivia(pieces: pieces) : trivia
    }
  }
}
