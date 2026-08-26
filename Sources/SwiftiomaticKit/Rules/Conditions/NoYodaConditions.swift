import SwiftSyntax

/// Prefer the constant value on the right-hand side of comparison expressions.
///
/// "Yoda conditions" place the constant on the left ( `0 == x` ), which reads unnaturally. The
/// conventional Swift style places the variable first ( `x == 0` ).
///
/// The rule reports the comparison and never rewrites it. Swapping the operands is only sound when
/// the operator resolves to the standard-library one, and a rule that reads one file at a time
/// cannot resolve types. An author may declare `==` , `<` and their siblings as a `static func` on
/// any type, with a reversed-operand overload that builds a different value. A query DSL does
/// exactly that: `2 == team.players.count` emits `2 = COUNT(...)` and the flipped form emits
/// `COUNT(...) = 2` . The two forms are different SQL, so the flip changes what the code does.
///
/// Lint: A comparison with a constant on the left raises a warning.
final class NoYodaConditions: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }

    private static let comparisonOperators: Set<String> = ["==", "!=", "<", "<=", ">", ">="]

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard let binOp = node.operator.as(BinaryOperatorExprSyntax.self),
            Self.comparisonOperators.contains(binOp.operator.text) else { return .visitChildren }

        // Only fire when LHS is constant and RHS is not
        guard Self.isConstant(node.leftOperand), !Self.isConstant(node.rightOperand)
        else { return .visitChildren }

        diagnose(.yodaCondition, on: node.leftOperand)
        return .visitChildren
    }

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
