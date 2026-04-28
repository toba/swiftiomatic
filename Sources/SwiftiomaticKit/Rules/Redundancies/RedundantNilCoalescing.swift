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
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard let concrete = visited.as(InfixOperatorExprSyntax.self) else { return visited }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: InfixOperatorExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let op = node.operator.as(BinaryOperatorExprSyntax.self),
            op.operator.tokenKind == .binaryOperator("??"),
            node.rightOperand.is(NilLiteralExprSyntax.self)
        else {
            return ExprSyntax(node)
        }

        Self.diagnose(.removeRedundantNilCoalescing, on: op.operator, context: context)

        // Strip the operator's leading space (which was the space between LHS and `??`)
        // by clearing the LHS's trailing trivia.
        var newLeft = node.leftOperand
        newLeft.trailingTrivia = []
        // Preserve any trailing trivia that was on the RHS `nil` (e.g. line break).
        newLeft.trailingTrivia += node.rightOperand.trailingTrivia
        return newLeft
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantNilCoalescing: Finding.Message =
        "remove redundant '?? nil'; the value is unchanged"
}
