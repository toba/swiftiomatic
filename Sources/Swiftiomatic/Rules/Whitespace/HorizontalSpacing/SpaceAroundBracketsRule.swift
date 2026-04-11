import SwiftSyntax

struct SpaceAroundBracketsRule {
  static let id = "space_around_brackets"
  static let name = "Space Around Brackets"
  static let summary =
    "There should be no space between an identifier and opening bracket, and space after closing bracket before identifiers"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("foo[0]"),
      Example("foo as [String]"),
      Example("let a = [1, 2]"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("foo↓ [0]")
    ]
  }

  static var corrections: [Example: Example] {
    [:]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SpaceAroundBracketsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceAroundBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SubscriptCallExprSyntax) {
      // No space between callee and [
      let leftBracket = node.leftSquare
      guard let prevToken = leftBracket.previousToken(viewMode: .sourceAccurate)
      else { return }

      if prevToken.trailingTrivia.containsHorizontalWhitespace,
        !prevToken.trailingTrivia.containsNewlines()
      {
        violations.append(prevToken.endPositionBeforeTrailingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      // Strip trailing horizontal whitespace from callee token before `[` in subscript calls
      if token.trailingTrivia.containsHorizontalWhitespace,
        !token.trailingTrivia.containsNewlines(),
        let nextToken = token.nextToken(viewMode: .sourceAccurate),
        nextToken.tokenKind == .leftSquare,
        nextToken.parent?.parent?.is(SubscriptCallExprSyntax.self) == true
      {
        numberOfCorrections += 1
        let strippedTrivia = Trivia(
          pieces: token.trailingTrivia.filter { !$0.isHorizontalWhitespace },
        )
        return super.visit(token.with(\.trailingTrivia, strippedTrivia))
      }
      return super.visit(token)
    }
  }
}
