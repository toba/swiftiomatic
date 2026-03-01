import SwiftSyntax

struct SpaceInsideGenericsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "space_inside_generics",
    name: "Space Inside Generics",
    description: "There should be no spaces immediately inside angle brackets",
    scope: .format,
    nonTriggeringExamples: [
      Example("let a: Array<Int> = []"),
      Example("func foo<T>() {}"),
    ],
    triggeringExamples: [
      Example("let a: Array↓< Int > = []"),
      Example("func foo↓< T >() {}"),
    ],
    corrections: [
      Example("let a: Array↓< Int > = []"): Example("let a: Array<Int> = []")
    ],
  )
}

extension SpaceInsideGenericsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension SpaceInsideGenericsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftAngle:
        if token.trailingTrivia.containsSpaces {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      case .rightAngle:
        if token.leadingTrivia.containsSpaces,
          !token.leadingTrivia.containsNewlines()
        {
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
      case .leftAngle:
        if token.trailingTrivia.containsSpaces {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightAngle:
        if token.leadingTrivia.containsSpaces,
          !token.leadingTrivia.containsNewlines()
        {
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
  fileprivate var containsSpaces: Bool {
    contains {
      switch $0 {
      case .spaces, .tabs:
        true
      default:
        false
      }
    }
  }
}
