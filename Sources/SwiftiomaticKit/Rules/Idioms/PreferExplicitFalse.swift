import SwiftSyntax

/// Prefer `== false` over `!` prefix negation.
///
/// The `!` prefix operator can be easy to miss, especially in complex conditions.
/// Using `== false` makes the negation explicit and more readable.
///
/// Lint: Using `!` prefix negation raises a warning.
///
/// Rewrite: `!expression` is replaced with `expression == false`.
final class PreferExplicitFalse: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard let concrete = visited.as(PrefixOperatorExprSyntax.self) else { return visited }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: PrefixOperatorExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard node.operator.text == "!" else { return ExprSyntax(node) }

        // Skip double negation: !!x (outer !)
        if node.expression.as(PrefixOperatorExprSyntax.self)?.operator.text == "!" {
            return ExprSyntax(node)
        }

        // Skip inner ! of double negation — check the captured original-tree parent.
        if let parentPrefix = parent?.as(PrefixOperatorExprSyntax.self),
            parentPrefix.operator.text == "!"
        {
            return ExprSyntax(node)
        }

        // Skip #if conditions
        if isInsideIfConfigCondition(parent: parent) { return ExprSyntax(node) }

        // Skip if adjacent to comparison or casting operators
        if isAdjacentToComparisonOrCasting(parent: parent) { return ExprSyntax(node) }

        Self.diagnose(.preferExplicitFalse, on: node.operator, context: context)

        // Build: expression == false
        var operandExpr = node.expression
        let savedTrailingTrivia = operandExpr.trailingTrivia
        operandExpr.leadingTrivia = node.leadingTrivia
        operandExpr.trailingTrivia = []

        let binOp = BinaryOperatorExprSyntax(
            operator: .binaryOperator("==", leadingTrivia: .space, trailingTrivia: .space)
        )
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

    // MARK: - Helpers

    private static let comparisonOperators: Set<String> = [
        "==", "!=", "===", "!==", "~=", "<", ">", "<=", ">=",
    ]

    /// Returns true if the node is inside the condition of an `#if` directive. Walks the
    /// captured pre-recursion parent chain.
    private static func isInsideIfConfigCondition(parent: Syntax?) -> Bool {
        // Walk parent upward; the first IfConfigClause we hit determines membership.
        // If our walked-from-child id equals `ifConfig.condition?.id`, we are the condition.
        var prev: Syntax? = nil
        var current = parent
        while let p = current {
            if let ifConfig = p.as(IfConfigClauseSyntax.self) {
                if let condition = ifConfig.condition, let prev, condition.id == prev.id {
                    return true
                }
                return false
            }
            prev = p
            current = p.parent
        }
        return false
    }

    /// Returns true if the node is an operand of a comparison (`==`, `!=`, etc.)
    /// or a type-casting expression (`is`, `as`). Uses the captured pre-recursion parent.
    private static func isAdjacentToComparisonOrCasting(parent: Syntax?) -> Bool {
        guard let parent else { return false }

        if let infix = parent.as(InfixOperatorExprSyntax.self) {
            if let binOp = infix.operator.as(BinaryOperatorExprSyntax.self) {
                if Self.comparisonOperators.contains(binOp.operator.text) { return true }
            }
        }

        if parent.is(IsExprSyntax.self) || parent.is(AsExprSyntax.self) { return true }

        return false
    }
}

extension Finding.Message {
    fileprivate static let preferExplicitFalse: Finding.Message =
        "prefer '== false' over '!' prefix negation"
}
