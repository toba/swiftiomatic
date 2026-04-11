import SwiftSyntax

struct SpaceAroundParensRule {
  static let id = "space_around_parens"
  static let name = "Space Around Parentheses"
  static let summary =
    "No space between function name and opening paren; space required after closing paren before identifiers"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("foo(bar)"),
      Example("init(foo: Int)"),
      Example("if (condition) {}"),
      Example("switch (x) {}"),
    ]
  }

  static var triggeringExamples: [Example] { [] }
  static var corrections: [Example: Example] { [:] }

  var options = SeverityOption<Self>(.warning)
}

extension SpaceAroundParensRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceAroundParensRule {
  // Keywords that should have a space before (
  private static let spaceBeforeParenKeywords: Set<Keyword> = [
    .if, .guard, .while, .for, .switch, .catch,
  ]

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let leftParen = node.leftParen else { return }
      checkNoSpaceBeforeLeftParen(leftParen)
    }

    override func visitPost(_: InitializerClauseSyntax) {
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
      if trivia.isHorizontalWhitespaceOnly, !trivia.containsNewlines() {
        violations.append(prevToken.endPositionBeforeTrailingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
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

      if leftParen.leadingTrivia.isHorizontalWhitespaceOnly,
        !leftParen.leadingTrivia.containsNewlines()
      {
        numberOfCorrections += 1
        let newParen = leftParen.with(\.leadingTrivia, Trivia())
        return super.visit(node.with(\.leftParen, newParen))
      }
      return super.visit(node)
    }
  }
}
