import SwiftSyntax

struct SpaceInsideParensRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "space_inside_parens",
    name: "Space Inside Parentheses",
    description: "There should be no spaces immediately inside parentheses",
    scope: .format,
    nonTriggeringExamples: [
      Example("(a, b)"),
      Example("foo(bar)"),
    ],
    triggeringExamples: [
      Example("(↓ a, b)"),
      Example("foo(↓ bar )"),
    ],
    corrections: [
      Example("(↓ a, b )"): Example("(a, b)")
    ],
  )
}

extension SpaceInsideParensRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension SpaceInsideParensRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftParen:
        if hasOnlySpaces(token.trailingTrivia) {
          violations.append(token.endPositionBeforeTrailingTrivia)
        }
      case .rightParen:
        if hasOnlySpaces(token.leadingTrivia) {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      default:
        break
      }
      return .visitChildren
    }

    private func hasOnlySpaces(_ trivia: Trivia) -> Bool {
      guard !trivia.isEmpty else { return false }
      return trivia.allSatisfy {
        switch $0 {
        case .spaces, .tabs:
          true
        default:
          false
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      switch token.tokenKind {
      case .leftParen:
        if hasOnlySpaces(token.trailingTrivia) {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightParen:
        if hasOnlySpaces(token.leadingTrivia) {
          numberOfCorrections += 1
          return super.visit(token.with(\.leadingTrivia, Trivia()))
        }
      default:
        break
      }
      return super.visit(token)
    }

    private func hasOnlySpaces(_ trivia: Trivia) -> Bool {
      guard !trivia.isEmpty else { return false }
      return trivia.allSatisfy {
        switch $0 {
        case .spaces, .tabs:
          true
        default:
          false
        }
      }
    }
  }
}
