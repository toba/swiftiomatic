import SwiftSyntax

/// Compact-pipeline merge of all `MemberAccessExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteMemberAccessExpr(
    _ node: MemberAccessExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    // PreferCountWhere — may widen `arr.filter { ... }.count` to
    // `arr.count(where: { ... })` (a `FunctionCallExprSyntax`). Direct
    // dispatch with early return when the kind changes.
    if context.shouldRewrite(PreferCountWhere.self, at: Syntax(result)) {
        let widened = PreferCountWhere.transform(result, parent: parent, context: context)
        if let stillMember = widened.as(MemberAccessExprSyntax.self) {
            result = stillMember
        } else {
            return widened
        }
    }

    context.applyRewrite(
        PreferIsDisjoint.self, to: &result,
        parent: parent, transform: PreferIsDisjoint.transform
    )

    context.applyRewrite(
        PreferSelfType.self, to: &result,
        parent: parent, transform: PreferSelfType.transform
    )

    // RedundantSelf — may widen `self.bar` to `bar` (a `DeclReferenceExpr`).
    // Direct dispatch with early return when the kind changes; subsequent
    // rules in this chain expect a `MemberAccessExprSyntax`.
    if context.shouldRewrite(RedundantSelf.self, at: Syntax(result)) {
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
    if context.shouldRewrite(RedundantStaticSelf.self, at: Syntax(result)) {
        let widened = RedundantStaticSelf.transform(result, parent: parent, context: context)
        if let stillMember = widened.as(MemberAccessExprSyntax.self) {
            result = stillMember
        } else {
            return widened
        }
    }

    // NoForceUnwrap — chain-top wrapping for force-unwrap chains. Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)) {
        return NoForceUnwrap.rewriteMemberAccess(result, context: context)
    }

    return ExprSyntax(result)
}
