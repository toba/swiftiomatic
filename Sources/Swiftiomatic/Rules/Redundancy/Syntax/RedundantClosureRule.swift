import SwiftSyntax

struct RedundantClosureRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantClosureConfiguration()
}

extension RedundantClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      // Looking for `{ ... }()` pattern (immediately-invoked closure)
      guard let closureExpr = node.calledExpression.as(ClosureExprSyntax.self),
        node.arguments.isEmpty,
        node.trailingClosure == nil
      else { return }

      // Must be a single-statement closure
      guard closureExpr.statements.count == 1 else { return }

      // Must not have parameters (closure signature)
      guard closureExpr.signature == nil else { return }

      // The single statement should be a return or a simple expression
      guard let onlyStmt = closureExpr.statements.first else { return }
      let isReturn = onlyStmt.item.is(ReturnStmtSyntax.self)
      let isExpr = onlyStmt.item.is(ExprSyntax.self)
      guard isReturn || isExpr else { return }

      violations.append(closureExpr.positionAfterSkippingLeadingTrivia)
    }
  }
}
