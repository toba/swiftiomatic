import SwiftSyntax

struct SpaceAroundParensRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "space_around_parens",
    name: "Space Around Parentheses",
    description:
      "No space between function name and opening paren; space required after closing paren before identifiers",
    scope: .format,
    nonTriggeringExamples: [
      Example("foo(bar)"),
      Example("init(foo: Int)"),
      Example("if (condition) {}"),
      Example("switch (x) {}"),
    ],
    triggeringExamples: [
      Example("foo↓ (bar)"),
      Example("init↓ (foo: Int)"),
    ],
    corrections: [
      Example("foo↓ (bar)"): Example("foo(bar)")
    ],
  )
}

extension SpaceAroundParensRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension SpaceAroundParensRule {
  // Keywords that should have a space before (
  private static let spaceBeforeParenKeywords: Set<Keyword> = [
    .if, .guard, .while, .for, .switch, .catch,
  ]

  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let leftParen = node.leftParen else { return }
      checkNoSpaceBeforeLeftParen(leftParen)
    }

    override func visitPost(_ node: InitializerClauseSyntax) {
      // Skip — this is `= value`, not a paren call
    }

    private func checkNoSpaceBeforeLeftParen(_ leftParen: TokenSyntax) {
      guard let prevToken = leftParen.previousToken(viewMode: .sourceAccurate) else { return }

      // Skip if the previous token is a keyword that needs space before (
      if case .keyword(let kw) = prevToken.tokenKind,
        SpaceAroundParensRule.spaceBeforeParenKeywords.contains(kw)
      {
        return
      }

      let trivia = leftParen.leadingTrivia
      if trivia.containsSpacesOnly, !trivia.containsNewlines() {
        violations.append(prevToken.endPositionBeforeTrailingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard let leftParen = node.leftParen else { return super.visit(node) }
      guard let prevToken = leftParen.previousToken(viewMode: .sourceAccurate) else {
        return super.visit(node)
      }

      if case .keyword(let kw) = prevToken.tokenKind,
        SpaceAroundParensRule.spaceBeforeParenKeywords.contains(kw)
      {
        return super.visit(node)
      }

      if leftParen.leadingTrivia.containsSpacesOnly, !leftParen.leadingTrivia.containsNewlines() {
        numberOfCorrections += 1
        let newParen = leftParen.with(\.leadingTrivia, Trivia())
        return super.visit(node.with(\.leftParen, newParen))
      }
      return super.visit(node)
    }
  }
}

extension Trivia {
  fileprivate var containsSpacesOnly: Bool {
    guard !isEmpty else { return false }
    return allSatisfy {
      switch $0 {
      case .spaces, .tabs: true
      default: false
      }
    }
  }
}
