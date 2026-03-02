import SwiftSyntax

struct SpaceInsideParensRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SpaceInsideParensConfiguration()
}

extension SpaceInsideParensRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceInsideParensRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftParen:
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          violations.append(token.endPositionBeforeTrailingTrivia)
        }
      case .rightParen:
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
      case .leftParen:
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightParen:
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
