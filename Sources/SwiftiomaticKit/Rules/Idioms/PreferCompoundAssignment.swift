import SwiftSyntax

/// Prefer compound assignment operators (`+=`, `-=`, `*=`, `/=`) over the long form.
///
/// `x = x + y` is exactly equivalent to `x += y` for the supported operators (`+`, `-`, `*`, `/`).
/// The compound form is shorter and avoids repeating the LHS, which makes refactors safer when the
/// receiver is renamed.
///
/// The rule fires only when the LHS expression text matches the RHS's first operand exactly. It
/// does not fire on `x = a + x` or `x = a + b` patterns.
///
/// Lint: A warning is raised for `x = x + y` etc.
///
/// Format: The expression is rewritten to `x += y`.
final class PreferCompoundAssignment: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    private static let supportedOperators: Set<String> = ["+", "-", "*", "/"]

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let infix = visited.as(InfixOperatorExprSyntax.self),
            infix.operator.is(AssignmentExprSyntax.self),
            let rhsInfix = infix.rightOperand.as(InfixOperatorExprSyntax.self),
            let rhsBinOp = rhsInfix.operator.as(BinaryOperatorExprSyntax.self),
            Self.supportedOperators.contains(rhsBinOp.operator.text),
            infix.leftOperand.trimmedDescription == rhsInfix.leftOperand.trimmedDescription
        else { return visited }

        diagnose(.preferCompoundAssignment(op: rhsBinOp.operator.text), on: infix.leftOperand)

        // Build `<lhs> <op>= <rhsRight>` while preserving outer trivia. Strip the LHS's trailing
        // trivia and the new RHS's leading trivia so the new operator can supply its own spacing.
        var newLHS = infix.leftOperand
        newLHS.trailingTrivia = []

        let compoundOpText = "\(rhsBinOp.operator.text)="
        let assignToken = TokenSyntax.binaryOperator(
            compoundOpText,
            leadingTrivia: .space,
            trailingTrivia: .space
        )
        let assignOp = BinaryOperatorExprSyntax(operator: assignToken)

        var newRHS = rhsInfix.rightOperand
        newRHS.leadingTrivia = []
        newRHS.trailingTrivia = infix.trailingTrivia

        let newInfix = InfixOperatorExprSyntax(
            leftOperand: newLHS,
            operator: ExprSyntax(assignOp),
            rightOperand: newRHS
        )
        return ExprSyntax(newInfix)
    }
}

extension Finding.Message {
    fileprivate static func preferCompoundAssignment(op: String) -> Finding.Message {
        "prefer compound assignment '\(op)='"
    }
}
