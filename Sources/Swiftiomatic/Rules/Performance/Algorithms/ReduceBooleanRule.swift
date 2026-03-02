import SwiftSyntax

struct ReduceBooleanRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ReduceBooleanConfiguration()
}

extension ReduceBooleanRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ReduceBooleanRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
        calledExpression.declName.baseName.text == "reduce",
        let firstArgument = node.arguments.first,
        firstArgument.label?.text ?? "into" == "into",
        let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
      else {
        return
      }

      let suggestedFunction = bool.literal.tokenKind == .keyword(.true) ? "allSatisfy" : "contains"
      violations.append(
        SyntaxViolation(
          position: calledExpression.declName.baseName.positionAfterSkippingLeadingTrivia,
          reason: "Use `\(suggestedFunction)` instead",
        ),
      )
    }
  }
}
