import SwiftSyntax

/// Prefer the constant value on the right-hand side of comparison expressions.
///
/// "Yoda conditions" place the constant on the left ( `0 == x` ), which reads unnaturally. The
/// conventional Swift style places the variable first ( `x == 0` ).
///
/// For ordered comparisons ( `<` , `<=` , `>` , `>=` ), the operator is flipped when swapping sides
/// so the semantics are preserved.
///
/// Lint: A comparison with a constant on the left raises a warning.
///
/// Rewrite: The operands are swapped and the operator is flipped if necessary.
final class NoYodaConditions: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }

    static func transform(
        _ node: InfixOperatorExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let binOp = node.operator.as(BinaryOperatorExprSyntax.self)
        else { return ExprSyntax(node) }

        let op = binOp.operator.text
        guard let flippedOp = Self.flippedOperators[op] else { return ExprSyntax(node) }

        // Only fire when LHS is constant and RHS is not
        guard isConstant(node.leftOperand), !isConstant(node.rightOperand)
        else { return ExprSyntax(node) }

        Self.diagnose(.yodaCondition, on: node.leftOperand, context: context)

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

    /// Returns `true` if the expression is a compile-time constant (literal, nil, bool, enum
    /// member).
    private static func isConstant(_ expr: ExprSyntax) -> Bool {
        if expr.is(IntegerLiteralExprSyntax.self)
            || expr.is(FloatLiteralExprSyntax.self)
            || expr.is(StringLiteralExprSyntax.self)
            || expr.is(NilLiteralExprSyntax.self)
            || expr.is(BooleanLiteralExprSyntax.self)
        {
            true
        } else if let memberAccess = expr.as(MemberAccessExprSyntax.self),
           memberAccess.base == nil
        {
            true
        } else {
            false
        }
    }
}

fileprivate extension Finding.Message {
    static let yodaCondition: Finding.Message =
        "place the constant on the right side of the comparison"
}
