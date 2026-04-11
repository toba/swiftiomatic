import SwiftSyntax

struct SpaceInsideGenericsRule {
  static let id = "space_inside_generics"
  static let name = "Space Inside Generics"
  static let summary = "There should be no spaces immediately inside angle brackets"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let a: Array<Int> = []"),
      Example("func foo<T>() {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let a: Array↓< Int > = []"),
      Example("func foo↓< T >() {}"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let a: Array↓< Int > = []"): Example("let a: Array<Int > = []")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SpaceInsideGenericsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceInsideGenericsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftAngle:
        if token.trailingTrivia.containsHorizontalWhitespace {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      case .rightAngle:
        if token.leadingTrivia.containsHorizontalWhitespace,
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

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      switch token.tokenKind {
      case .leftAngle:
        if token.trailingTrivia.containsHorizontalWhitespace {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightAngle:
        if token.leadingTrivia.containsHorizontalWhitespace,
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
