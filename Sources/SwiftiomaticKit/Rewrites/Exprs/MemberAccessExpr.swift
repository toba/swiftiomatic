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

    // PreferCountWhere — may widen `arr.filter { ... }.count` to
    // `arr.count(where: { ... })` (a `FunctionCallExprSyntax`). Direct
    // dispatch with early return when the kind changes.
    if context.shouldFormat(PreferCountWhere.self, node: Syntax(result)) {
        let widened = PreferCountWhere.transform(result, parent: parent, context: context)
        if let stillMember = widened.as(MemberAccessExprSyntax.self) {
            result = stillMember
        } else {
            return widened
        }
    }

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

    // RedundantSelf — may widen `self.bar` to `bar` (a `DeclReferenceExpr`).
    // Direct dispatch with early return when the kind changes; subsequent
    // rules in this chain expect a `MemberAccessExprSyntax`.
    if context.shouldFormat(RedundantSelf.self, node: Syntax(result)) {
        let widened = RedundantSelf.transform(result, parent: parent, context: context)
        if let stillMember = widened.as(MemberAccessExprSyntax.self) {
            result = stillMember
        } else {
            return widened
        }
    }

    // RedundantStaticSelf — may widen `Self.foo` (member access) to `foo`
    // (a `DeclReferenceExpr`). Direct dispatch with early return when the
    // kind changes.
    if context.shouldFormat(RedundantStaticSelf.self, node: Syntax(result)) {
        let widened = RedundantStaticSelf.transform(result, parent: parent, context: context)
        if let stillMember = widened.as(MemberAccessExprSyntax.self) {
            result = stillMember
        } else {
            return widened
        }
    }

    // NoForceUnwrap — chain-top wrapping for force-unwrap chains. Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        return noForceUnwrapRewriteMemberAccess(result, context: context)
    }

    return ExprSyntax(result)
}
