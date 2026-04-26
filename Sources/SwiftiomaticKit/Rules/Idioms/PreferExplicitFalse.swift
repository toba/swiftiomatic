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
        guard node.operator.text == "!" else { return super.visit(node) }

        // Skip double negation: !!x (outer !)
        if node.expression.as(PrefixOperatorExprSyntax.self)?.operator.text == "!" {
            return super.visit(node)
        }

        // Skip inner ! of double negation
        if let parentPrefix = node.parent?.as(PrefixOperatorExprSyntax.self),
            parentPrefix.operator.text == "!"
        {
            return super.visit(node)
        }

        // Skip #if conditions
        if isInsideIfConfigCondition(node) { return super.visit(node) }

        // Skip if adjacent to comparison or casting operators
        if isAdjacentToComparisonOrCasting(node) { return super.visit(node) }

        let visited = super.visit(node)
        guard let prefixNode = visited.as(PrefixOperatorExprSyntax.self) else { return visited }

        diagnose(.preferExplicitFalse, on: prefixNode.operator)

        // Build: expression == false
        var operandExpr = prefixNode.expression
        let savedTrailingTrivia = operandExpr.trailingTrivia
        operandExpr.leadingTrivia = prefixNode.leadingTrivia
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

    /// Returns true if the node is inside the condition of an `#if` directive.
    private func isInsideIfConfigCondition(_ node: some SyntaxProtocol) -> Bool {
        var current = Syntax(node)

        while let parent = current.parent {
            if let ifConfig = parent.as(IfConfigClauseSyntax.self) {
                if let condition = ifConfig.condition, condition.id == current.id { return true }
                return false
            }
            current = parent
        }
        return false
    }

    /// Returns true if the node is an operand of a comparison (`==`, `!=`, etc.)
    /// or a type-casting expression (`is`, `as`).
    private func isAdjacentToComparisonOrCasting(_ node: PrefixOperatorExprSyntax) -> Bool {
        guard let parent = node.parent else { return false }

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
