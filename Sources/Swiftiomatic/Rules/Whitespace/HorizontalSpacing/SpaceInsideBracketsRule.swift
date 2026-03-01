import SwiftSyntax

struct SpaceInsideBracketsRule: Rule {
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
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension SpaceInsideBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftSquare:
        // Check if trailing trivia has spaces (no linebreak means inline)
        if token.trailingTrivia.hasSpacesOnly {
          violations.append(token.endPositionBeforeTrailingTrivia)
        }
      case .rightSquare:
        // Check if leading trivia has only spaces (not preceded by linebreak or comment)
        if token.leadingTrivia.hasSpacesOnly {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      default:
        break
      }
      return .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      switch token.tokenKind {
      case .leftSquare:
        if token.trailingTrivia.hasSpacesOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightSquare:
        if token.leadingTrivia.hasSpacesOnly {
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

extension Trivia {
  fileprivate var hasSpacesOnly: Bool {
    guard !isEmpty else { return false }
    return allSatisfy {
      switch $0 {
      case .spaces, .tabs:
        true
      default:
        false
      }
    }
  }
}
