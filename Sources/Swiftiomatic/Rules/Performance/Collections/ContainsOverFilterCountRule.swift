import SwiftSyntax

struct ContainsOverFilterCountRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ContainsOverFilterCountConfiguration()
}

extension ContainsOverFilterCountRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContainsOverFilterCountRule {}

extension ContainsOverFilterCountRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExprListSyntax) {
      guard
        node.count == 3,
        let last = node.last?.as(IntegerLiteralExprSyntax.self),
        last.isZero,
        let second = node.dropFirst().first,
        second.firstToken(viewMode: .sourceAccurate)?.tokenKind.isZeroComparison == true,
        let first = node.first?.as(MemberAccessExprSyntax.self),
        first.declName.baseName.text == "count",
        let firstBase = first.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "filter"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension TokenKind {
  fileprivate var isZeroComparison: Bool {
    self == .binaryOperator("==") || self == .binaryOperator("!=") || self == .binaryOperator(">")
  }
}
