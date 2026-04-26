import SwiftSyntax

/// Remove nil-coalescing where the right-hand side is `nil`.
///
/// `x ?? nil` is identical in value and type to `x` itself.
///
/// Lint: A finding is raised when `??` has a `nil` literal on the right-hand side.
///
/// Rewrite: The `??` operator and the `nil` right-hand side are removed.
final class RedundantNilCoalescing: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
        guard let op = node.operator.as(BinaryOperatorExprSyntax.self),
            op.operator.tokenKind == .binaryOperator("??"),
            node.rightOperand.is(NilLiteralExprSyntax.self)
        else {
            return super.visit(node)
        }

        diagnose(.removeRedundantNilCoalescing, on: op.operator)

        // Strip the operator's leading space (which was the space between LHS and `??`)
        // by clearing the LHS's trailing trivia.
        var newLeft = node.leftOperand
        newLeft.trailingTrivia = []
        // Preserve any trailing trivia that was on the RHS `nil` (e.g. line break).
        newLeft.trailingTrivia += node.rightOperand.trailingTrivia
        return super.visit(newLeft)
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantNilCoalescing: Finding.Message =
        "remove redundant '?? nil'; the value is unchanged"
}
