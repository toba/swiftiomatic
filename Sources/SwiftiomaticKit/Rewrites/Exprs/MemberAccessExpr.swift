import SwiftSyntax

/// Compact-pipeline merge of all `MemberAccessExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteMemberAccessExpr(
    _ node: MemberAccessExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    applyRule(
        PreferCountWhere.self, to: &result,
        parent: parent, context: context,
        transform: PreferCountWhere.transform
    )

    applyRule(
        PreferIsDisjoint.self, to: &result,
        parent: parent, context: context,
        transform: PreferIsDisjoint.transform
    )

    applyRule(
        PreferSelfType.self, to: &result,
        parent: parent, context: context,
        transform: PreferSelfType.transform
    )

    applyRule(
        RedundantSelf.self, to: &result,
        parent: parent, context: context,
        transform: RedundantSelf.transform
    )

    applyRule(
        RedundantStaticSelf.self, to: &result,
        parent: parent, context: context,
        transform: RedundantStaticSelf.transform
    )

    // NoForceUnwrap — chain-top wrapping for force-unwrap chains. Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        return noForceUnwrapRewriteMemberAccess(result, context: context)
    }

    return ExprSyntax(result)
}
