import SwiftSyntax

struct RedundantParensRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantParensConfiguration()
}

extension RedundantParensRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantParensRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ConditionElementSyntax) {
      guard let condition = node.condition.as(ExprSyntax.self)
      else { return }
      if let tupleExpr = condition.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      {
        violations.append(tupleExpr.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
      guard let expr = node.expression,
        let tupleExpr = expr.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return }
      violations.append(tupleExpr.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
      guard let condition = node.condition.as(ExprSyntax.self),
        let tupleExpr = condition.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return super.visit(node) }

      numberOfCorrections += 1
      let unwrapped = onlyElement.expression
        .with(\.leadingTrivia, tupleExpr.leadingTrivia)
        .with(\.trailingTrivia, tupleExpr.trailingTrivia)
      return super.visit(node.with(\.condition, .expression(unwrapped)))
    }

    override func visit(_ node: ReturnStmtSyntax) -> StmtSyntax {
      guard let expr = node.expression,
        let tupleExpr = expr.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return super.visit(node) }

      numberOfCorrections += 1
      let unwrapped = onlyElement.expression
        .with(\.leadingTrivia, expr.leadingTrivia)
        .with(\.trailingTrivia, expr.trailingTrivia)
      return super.visit(node.with(\.expression, unwrapped))
    }
  }
}
