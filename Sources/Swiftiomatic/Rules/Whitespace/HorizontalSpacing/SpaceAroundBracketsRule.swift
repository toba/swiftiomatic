import SwiftSyntax

struct SpaceAroundBracketsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "space_around_brackets",
    name: "Space Around Brackets",
    description:
      "There should be no space between an identifier and opening bracket, and space after closing bracket before identifiers",
    scope: .format,
    nonTriggeringExamples: [
      Example("foo[0]"),
      Example("foo as [String]"),
      Example("let a = [1, 2]"),
    ],
    triggeringExamples: [
      Example("foo↓ [0]"),
      Example("foo↓as[String]"),
    ],
    corrections: [
      Example("foo↓ [0]"): Example("foo[0]")
    ],
  )
}

extension SpaceAroundBracketsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension SpaceAroundBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: SubscriptCallExprSyntax) {
      // No space between callee and [
      let leftBracket = node.leftSquare
      guard let prevToken = leftBracket.previousToken(viewMode: .sourceAccurate) else { return }

      if prevToken.trailingTrivia.hasSpacesNotNewlines,
        !prevToken.trailingTrivia.containsNewlines()
      {
        violations.append(prevToken.endPositionBeforeTrailingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
      let leftBracket = node.leftSquare
      guard let prevToken = leftBracket.previousToken(viewMode: .sourceAccurate) else {
        return super.visit(node)
      }

      if prevToken.trailingTrivia.hasSpacesNotNewlines,
        !prevToken.trailingTrivia.containsNewlines()
      {
        numberOfCorrections += 1
        // Remove space from the previous token's trailing trivia
        // We need to modify the parent tree, so we modify the left bracket's leading trivia
        let newLeftBracket = leftBracket.with(\.leadingTrivia, Trivia())
        let newNode = node.with(\.leftSquare, newLeftBracket)
        return super.visit(newNode)
      }
      return super.visit(node)
    }
  }
}

extension Trivia {
  fileprivate var hasSpacesNotNewlines: Bool {
    let hasSpace = contains {
      switch $0 {
      case .spaces, .tabs: true
      default: false
      }
    }
    return hasSpace && !containsNewlines()
  }
}
