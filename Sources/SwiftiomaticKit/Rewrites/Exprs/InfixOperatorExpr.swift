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
) -> InfixOperatorExprSyntax {
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

    applyRule(
        PreferIsEmpty.self, to: &result,
        parent: parent, context: context,
        transform: PreferIsEmpty.transform
    )

    applyRule(
        PreferToggle.self, to: &result,
        parent: parent, context: context,
        transform: PreferToggle.transform
    )

    applyRule(
        RedundantNilCoalescing.self, to: &result,
        parent: parent, context: context,
        transform: RedundantNilCoalescing.transform
    )

    applyRule(
        WrapConditionalAssignment.self, to: &result,
        parent: parent, context: context,
        transform: WrapConditionalAssignment.transform
    )

    return result
}
