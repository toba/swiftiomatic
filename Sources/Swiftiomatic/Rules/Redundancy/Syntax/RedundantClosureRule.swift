import SwiftSyntax

struct RedundantClosureRule {
    static let id = "redundant_closure"
    static let name = "Redundant Closure"
    static let summary = "Immediately-invoked closures with a single expression can be simplified"
    static let scope: Scope = .format
    static var nonTriggeringExamples: [Example] {
        [
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
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                let x: Int = ↓{
                  return 42
                }()
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
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
