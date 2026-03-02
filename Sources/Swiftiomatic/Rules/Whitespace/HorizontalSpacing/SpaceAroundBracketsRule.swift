import SwiftSyntax

struct SpaceAroundBracketsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SpaceAroundBracketsConfiguration()
}

extension SpaceAroundBracketsRule: SwiftSyntaxCorrectableRule {
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
      guard let prevToken = leftBracket.previousToken(viewMode: .sourceAccurate) else { return }

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
          pieces: token.trailingTrivia.filter { !$0.isHorizontalWhitespace })
        return super.visit(token.with(\.trailingTrivia, strippedTrivia))
      }
      return super.visit(token)
    }
  }
}
