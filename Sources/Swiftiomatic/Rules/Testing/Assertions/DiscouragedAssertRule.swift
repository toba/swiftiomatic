import SwiftSyntax

struct DiscouragedAssertRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DiscouragedAssertConfiguration()
}

extension DiscouragedAssertRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedAssertRule {}

extension DiscouragedAssertRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "assert",
        let firstArg = node.arguments.first,
        firstArg.label == nil,
        let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
        boolExpr.literal.tokenKind == .keyword(.false)
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
