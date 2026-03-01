import SwiftSyntax

struct RedundantClosureRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_closure",
    name: "Redundant Closure",
    description: "Immediately-invoked closures with a single expression can be simplified",
    scope: .format,
    nonTriggeringExamples: [
      Example("let x = { 42 }()"),
      Example(
        """
        let x = {
          let y = 10
          return y + 1
        }()
        """,
      ),
      Example(
        """
        let x = { (a: Int) in a + 1 }(5)
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        let x: Int = ↓{
          return 42
        }()
        """,
      )
    ],
  )
}

extension RedundantClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension RedundantClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
