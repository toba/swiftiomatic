import SwiftSyntax

struct SpaceAroundCommentsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SpaceAroundCommentsConfiguration()
}

extension SpaceAroundCommentsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceAroundCommentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      // Check if a line comment in leading trivia is not preceded by a space
      // (i.e., directly after code on the same line, no space between)
      let leading = token.leadingTrivia
      var position = token.position
      var prevWasSpace = true  // Start of line counts as having space

      for piece in leading {
        switch piece {
        case .lineComment, .docLineComment:
          if !prevWasSpace {
            violations.append(position)
          }
          prevWasSpace = false
        case .blockComment, .docBlockComment:
          if !prevWasSpace {
            violations.append(position)
          }
          prevWasSpace = false
        case .spaces, .tabs:
          prevWasSpace = true
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
          prevWasSpace = true  // Start of line
        default:
          prevWasSpace = false
        }
        position = position.advanced(by: piece.sourceLength.utf8Length)
      }
      return .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      let leading = token.leadingTrivia
      var newPieces = [TriviaPiece]()
      var prevWasSpace = true
      var changed = false

      for piece in leading {
        switch piece {
        case .lineComment, .docLineComment, .blockComment, .docBlockComment:
          if !prevWasSpace {
            newPieces.append(.spaces(1))
            changed = true
          }
          newPieces.append(piece)
          prevWasSpace = false
        case .spaces, .tabs:
          prevWasSpace = true
          newPieces.append(piece)
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
          prevWasSpace = true
          newPieces.append(piece)
        default:
          prevWasSpace = false
          newPieces.append(piece)
        }
      }

      if changed {
        numberOfCorrections += 1
        return super.visit(token.with(\.leadingTrivia, Trivia(pieces: newPieces)))
      }
      return super.visit(token)
    }
  }
}
