import SwiftSyntax

struct SpaceInsideBracketsRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "space_inside_brackets",
    name: "Space Inside Brackets",
    description: "There should be no spaces immediately inside square brackets",
    scope: .format,
    nonTriggeringExamples: [
      Example("let a = [1, 2, 3]"),
      Example("let b = foo[0]"),
    ],
    triggeringExamples: [
      Example("let a = [↓ 1, 2, 3 ]"),
      Example("let b = foo[↓ 0 ]"),
    ],
    corrections: [
      Example("let a = [↓ 1, 2, 3 ]"): Example("let a = [1, 2, 3]")
    ],
  )
}

extension SpaceInsideBracketsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: configuration, file: file)
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
