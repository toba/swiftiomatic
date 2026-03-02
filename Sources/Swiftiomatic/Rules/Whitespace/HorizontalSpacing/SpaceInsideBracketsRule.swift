import SwiftSyntax

struct SpaceInsideBracketsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SpaceInsideBracketsConfiguration()
}

extension SpaceInsideBracketsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceInsideBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftSquare:
        // Check if trailing trivia has spaces (no linebreak means inline)
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          violations.append(token.endPositionBeforeTrailingTrivia)
        }
      case .rightSquare:
        // Check if leading trivia has only spaces (not preceded by linebreak or comment)
        if token.leadingTrivia.isHorizontalWhitespaceOnly {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      default:
        break
      }
      return .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      switch token.tokenKind {
      case .leftSquare:
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightSquare:
        if token.leadingTrivia.isHorizontalWhitespaceOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.leadingTrivia, Trivia()))
        }
      default:
        break
      }
      return super.visit(token)
    }
  }
}
