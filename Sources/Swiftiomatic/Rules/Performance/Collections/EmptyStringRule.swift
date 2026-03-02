import SwiftSyntax

struct EmptyStringRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyStringConfiguration()
}

extension EmptyStringRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StringLiteralExprSyntax) {
      guard
        // Empty string literal: `""`, `#""#`, etc.
        node.segments.onlyElement?.trimmedLength == .zero,
        let previousToken = node.previousToken(viewMode: .sourceAccurate),
        // On the rhs of an `==` or `!=` operator
        previousToken.tokenKind.isEqualityComparison,
        let secondPreviousToken = previousToken.previousToken(viewMode: .sourceAccurate)
      else {
        return
      }

      let violationPosition = secondPreviousToken.endPositionBeforeTrailingTrivia
      violations.append(violationPosition)
    }
  }
}

extension EmptyStringRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EmptyStringRule {}
