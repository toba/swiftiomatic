import SwiftSyntax

/// Comparing two identical operands is almost always a copy-paste bug.
///
/// Catches expressions like `x == x`, `foo.bar < foo.bar`, and `$0 != $0`.
/// Compares operands by their non-trivia token text so internal whitespace
/// and formatting differences are ignored.
///
/// Lint: When both operands of a comparison operator are textually identical
/// (ignoring whitespace), a warning is raised.
final class IdenticalOperands: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var defaultValue: LintOnlyValue { LintOnlyValue(lint: .no) }

    private static let comparisonOperators: Set<String> = [
        "==", "!=", "===", "!==", ">", ">=", "<", "<=",
    ]

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard let binOp = node.operator.as(BinaryOperatorExprSyntax.self),
            Self.comparisonOperators.contains(binOp.operator.text)
        else {
            return .visitChildren
        }

        if normalized(node.leftOperand) == normalized(node.rightOperand) {
            diagnose(.identicalOperands, on: node.leftOperand)
        }
        return .visitChildren
    }

    /// Returns the joined source-accurate token text of `expr`, ignoring
    /// trivia (whitespace and comments).
    private func normalized(_ expr: ExprSyntax) -> String {
        expr.tokens(viewMode: .sourceAccurate)
            .map(\.text)
            .joined()
    }
}

extension Finding.Message {
    fileprivate static let identicalOperands: Finding.Message =
        "comparing two identical operands is likely a mistake"
}
