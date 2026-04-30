import SwiftSyntax

/// Compact-pipeline merge of all `InfixOperatorExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteInfixOperatorExpr(
    _ node: InfixOperatorExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    context.applyRewrite(
        NoAssignmentInExpressions.self, to: &result,
        parent: parent, transform: NoAssignmentInExpressions.transform
    )

    context.applyRewrite(
        NoYodaConditions.self, to: &result,
        parent: parent, transform: NoYodaConditions.transform
    )

    context.applyRewrite(
        PreferCompoundAssignment.self, to: &result,
        parent: parent, transform: PreferCompoundAssignment.transform
    )

    // PreferIsEmpty — may widen `foo.count == 0` to `foo.isEmpty` (a
    // `MemberAccessExprSyntax`). Direct dispatch with early return when the
    // kind changes.
    if context.shouldRewrite(PreferIsEmpty.self, at: Syntax(result)) {
        let widened = PreferIsEmpty.transform(result, parent: parent, context: context)
        if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
            result = stillInfix
        } else {
            return widened
        }
    }

    // PreferToggle — may widen `x = !x` to `x.toggle()` (a
    // `FunctionCallExprSyntax`). Direct dispatch with early return when the
    // kind changes.
    if context.shouldRewrite(PreferToggle.self, at: Syntax(result)) {
        let widened = PreferToggle.transform(result, parent: parent, context: context)
        if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
            result = stillInfix
        } else {
            return widened
        }
    }

    // RedundantNilCoalescing — may widen `x ?? nil` to just `x` (any
    // `ExprSyntax`). Direct dispatch with early return when the kind changes.
    if context.shouldRewrite(RedundantNilCoalescing.self, at: Syntax(result)) {
        let widened = RedundantNilCoalescing.transform(result, parent: parent, context: context)
        if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
            result = stillInfix
        } else {
            return widened
        }
    }

    context.applyRewrite(
        WrapConditionalAssignment.self, to: &result,
        parent: parent, transform: WrapConditionalAssignment.transform
    )

    return ExprSyntax(result)
}
