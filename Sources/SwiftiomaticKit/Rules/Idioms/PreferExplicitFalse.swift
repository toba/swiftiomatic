import SwiftSyntax

/// Prefer `== false` over `!` prefix negation.
///
/// The `!` prefix operator can be easy to miss, especially in complex conditions. Using `== false`
/// makes the negation explicit and more readable.
///
/// Lint: Using `!` prefix negation raises a warning.
///
/// Rewrite: `!expression` is replaced with `expression == false` .
final class PreferExplicitFalse: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Helpers

    private static let comparisonOperators: Set<String> = [
        "==", "!=", "===", "!==", "~=", "<", ">", "<=", ">=",
    ]

    // MARK: - Static transform (compact pipeline)

    static func transform(
        _ node: PrefixOperatorExprSyntax,
        original _: PrefixOperatorExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard node.operator.text == "!" else { return ExprSyntax(node) }

        // Skip double negation: !!x (outer !)
        if node.expression.as(PrefixOperatorExprSyntax.self)?.operator.text == "!" {
            return ExprSyntax(node)
        }

        // Skip inner ! of double negation — use captured pre-traversal parent.
        if let parentPrefix = parent?.as(PrefixOperatorExprSyntax.self),
           parentPrefix.operator.text == "!"
        {
            return ExprSyntax(node)
        }

        // Skip #if conditions — walk the captured parent chain.
        if Self.isInsideIfConfigCondition(parent: parent) { return ExprSyntax(node) }

        // Skip if adjacent to comparison or casting operators — use captured parent.
        if Self.isAdjacentToComparisonOrCasting(parent: parent) { return ExprSyntax(node) }

        Self.diagnose(.preferExplicitFalse, on: node.operator, context: context)

        // Build: expression == false
        var operandExpr = node.expression
        let savedTrailingTrivia = operandExpr.trailingTrivia
        operandExpr.leadingTrivia = node.leadingTrivia
        operandExpr.trailingTrivia = []

        let binOp = BinaryOperatorExprSyntax(
            operator: .binaryOperator(
                "==",
                leadingTrivia: .space,
                trailingTrivia: .space
            ))
        let falseExpr = BooleanLiteralExprSyntax(literal: .keyword(.false))

        var result = ExprSyntax(
            InfixOperatorExprSyntax(
                leftOperand: operandExpr,
                operator: ExprSyntax(binOp),
                rightOperand: ExprSyntax(falseExpr)
            ))
        result.trailingTrivia = savedTrailingTrivia
        return result
    }

    /// Static counterpart of `isInsideIfConfigCondition` that walks the captured pre-traversal
    /// parent chain instead of the (now-detached) node's chain.
    fileprivate static func isInsideIfConfigCondition(parent: Syntax?) -> Bool {
        // Walk up the captured parent chain. If we encounter an IfConfigClause whose `condition` is
        // an ancestor of (or equal to) the previously-seen child, the original node is somewhere in
        // that condition subtree — treat that as "inside".
        var prev: Syntax?
        var current = parent

        while let p = current {
            if let ifConfig = p.as(IfConfigClauseSyntax.self) {
                if let condition = ifConfig.condition,
                   let prev,
                   condition.id == prev.id || condition.id == prev.id
                {
                    return true
                }
                // Even if `prev` isn't directly the condition, a PrefixOperatorExpr appearing below
                // an IfConfigClause is necessarily within its condition.
                return true
            }
            prev = p
            current = p.parent
        }
        return false
    }

    /// Static counterpart of `isAdjacentToComparisonOrCasting` using the captured parent.
    fileprivate static func isAdjacentToComparisonOrCasting(parent: Syntax?) -> Bool {
        guard let parent else { return false }

        if let infix = parent.as(InfixOperatorExprSyntax.self) {
            if let binOp = infix.operator.as(BinaryOperatorExprSyntax.self) {
                if Self.comparisonOperators.contains(binOp.operator.text) { return true }
            }
        }

        return parent.is(IsExprSyntax.self) || parent.is(AsExprSyntax.self) ? true : false
    }
}

fileprivate extension Finding.Message {
    static let preferExplicitFalse: Finding.Message = "prefer '== false' over '!' prefix negation"
}
