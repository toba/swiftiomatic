import SwiftSyntax

/// Prefer the constant value on the right-hand side of comparison expressions.
///
/// "Yoda conditions" place the constant on the left (`0 == x`), which reads unnaturally.
/// The conventional Swift style places the variable first (`x == 0`).
///
/// For ordered comparisons (`<`, `<=`, `>`, `>=`), the operator is flipped when swapping
/// sides so the semantics are preserved.
///
/// Lint: A comparison with a constant on the left raises a warning.
///
/// Format: The operands are swapped and the operator is flipped if necessary.
final class NoYodaConditions: RewriteSyntaxRule<BasicRuleValue> {

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
        guard let binOp = node.operator.as(BinaryOperatorExprSyntax.self) else {
            return super.visit(node)
        }

        let op = binOp.operator.text
        guard let flippedOp = Self.flippedOperators[op] else {
            return super.visit(node)
        }

        // Only fire when LHS is constant and RHS is not
        guard isConstant(node.leftOperand), !isConstant(node.rightOperand) else {
            return super.visit(node)
        }

        diagnose(.yodaCondition, on: node.leftOperand)

        // Swap operands, preserving each side's leading/trailing trivia position
        var newLeft = node.rightOperand
        var newRight = node.leftOperand

        let leftLeading = node.leftOperand.leadingTrivia
        let leftTrailing = node.leftOperand.trailingTrivia
        let rightLeading = node.rightOperand.leadingTrivia
        let rightTrailing = node.rightOperand.trailingTrivia

        newLeft.leadingTrivia = leftLeading
        newLeft.trailingTrivia = leftTrailing
        newRight.leadingTrivia = rightLeading
        newRight.trailingTrivia = rightTrailing

        // Flip the operator if needed
        let newBinOp = binOp.with(
            \.operator,
            binOp.operator.with(\.tokenKind, .binaryOperator(flippedOp))
        )

        var result = node
        result.leftOperand = newLeft
        result.operator = ExprSyntax(newBinOp)
        result.rightOperand = newRight
        return ExprSyntax(result)
    }

    private static let flippedOperators: [String: String] = [
        "==": "==",
        "!=": "!=",
        "<": ">",
        "<=": ">=",
        ">": "<",
        ">=": "<=",
    ]

    /// Returns `true` if the expression is a compile-time constant (literal, nil, bool, enum member).
    private func isConstant(_ expr: ExprSyntax) -> Bool {
        if expr.is(IntegerLiteralExprSyntax.self)
            || expr.is(FloatLiteralExprSyntax.self)
            || expr.is(StringLiteralExprSyntax.self)
            || expr.is(NilLiteralExprSyntax.self)
            || expr.is(BooleanLiteralExprSyntax.self)
        {
            return true
        }

        // `.foo` enum member syntax (MemberAccessExpr with no base)
        if let memberAccess = expr.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil
        {
            return true
        }

        return false
    }
}

extension Finding.Message {
    fileprivate static let yodaCondition: Finding.Message =
        "place the constant on the right side of the comparison"
}
