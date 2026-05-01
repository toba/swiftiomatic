import SwiftSyntax

/// Prefer `someBool.toggle()` over `someBool = !someBool` .
///
/// `Bool.toggle()` (Swift 4.2+) is more concise and clearly communicates the intent. The two forms
/// are equivalent semantically; `toggle()` does not introduce any new evaluation hazards.
///
/// Lint: A warning is raised for `x = !x` patterns where the LHS and the negated RHS reference the
/// exact same expression text.
///
/// Rewrite: The expression is rewritten to `x.toggle()` .
final class PreferToggle: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    static func transform(
        _ node: InfixOperatorExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let infix = node
        guard infix.operator.is(AssignmentExprSyntax.self),
              let prefix = infix.rightOperand.as(PrefixOperatorExprSyntax.self),
              prefix.operator.text == "!" else { return ExprSyntax(infix) }

        let lhsText = infix.leftOperand.trimmedDescription
        let rhsInner = prefix.expression.trimmedDescription
        guard lhsText == rhsInner else { return ExprSyntax(infix) }

        Self.diagnose(.preferToggle, on: infix.leftOperand, context: context)

        // Build `<lhs>.toggle()` while preserving the surrounding trivia.
        var lhs = infix.leftOperand
        let originalLHSLeading = lhs.leadingTrivia
        lhs.leadingTrivia = []
        lhs.trailingTrivia = []

        let toggleAccess = MemberAccessExprSyntax(
            base: lhs,
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier("toggle"))
        )
        let call = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(toggleAccess),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([]),
            rightParen: .rightParenToken()
        )

        var result = ExprSyntax(call)
        result.leadingTrivia = originalLHSLeading
        result.trailingTrivia = infix.trailingTrivia
        return result
    }
}

fileprivate extension Finding.Message {
    static let preferToggle: Finding.Message = "prefer 'toggle()' over assigning the negation"
}
