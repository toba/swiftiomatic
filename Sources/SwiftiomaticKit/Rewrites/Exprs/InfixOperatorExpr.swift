import SwiftSyntax

/// Compact-pipeline merge of all `InfixOperatorExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteInfixOperatorExpr(
    _ node: InfixOperatorExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    applyRule(
        NoAssignmentInExpressions.self, to: &result,
        parent: parent, context: context,
        transform: NoAssignmentInExpressions.transform
    )

    applyRule(
        NoYodaConditions.self, to: &result,
        parent: parent, context: context,
        transform: NoYodaConditions.transform
    )

    applyRule(
        PreferCompoundAssignment.self, to: &result,
        parent: parent, context: context,
        transform: PreferCompoundAssignment.transform
    )

    // PreferIsEmpty — may widen `foo.count == 0` to `foo.isEmpty` (a
    // `MemberAccessExprSyntax`). Direct dispatch with early return when the
    // kind changes.
    if context.shouldFormat(PreferIsEmpty.self, node: Syntax(result)) {
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
    if context.shouldFormat(PreferToggle.self, node: Syntax(result)) {
        let widened = PreferToggle.transform(result, parent: parent, context: context)
        if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
            result = stillInfix
        } else {
            return widened
        }
    }

    // RedundantNilCoalescing — may widen `x ?? nil` to just `x` (any
    // `ExprSyntax`). Direct dispatch with early return when the kind changes.
    if context.shouldFormat(RedundantNilCoalescing.self, node: Syntax(result)) {
        let widened = RedundantNilCoalescing.transform(result, parent: parent, context: context)
        if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
            result = stillInfix
        } else {
            return widened
        }
    }

    applyRule(
        WrapConditionalAssignment.self, to: &result,
        parent: parent, context: context,
        transform: WrapConditionalAssignment.transform
    )

    return ExprSyntax(result)
}
