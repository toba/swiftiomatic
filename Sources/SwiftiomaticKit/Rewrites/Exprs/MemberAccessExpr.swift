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
    context: Context
) -> MemberAccessExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // PreferCountWhere
    if context.shouldFormat(PreferCountWhere.self, node: Syntax(result)) {
        if let next = PreferCountWhere.transform(
            result, parent: parent, context: context
        ).as(MemberAccessExprSyntax.self) {
            result = next
        }
    }

    // PreferIsDisjoint
    if context.shouldFormat(PreferIsDisjoint.self, node: Syntax(result)) {
        if let next = PreferIsDisjoint.transform(
            result, parent: parent, context: context
        ).as(MemberAccessExprSyntax.self) {
            result = next
        }
    }

    // PreferSelfType
    if context.shouldFormat(PreferSelfType.self, node: Syntax(result)) {
        if let next = PreferSelfType.transform(
            result, parent: parent, context: context
        ).as(MemberAccessExprSyntax.self) {
            result = next
        }
    }

    // RedundantSelf
    if context.shouldFormat(RedundantSelf.self, node: Syntax(result)) {
        if let next = RedundantSelf.transform(
            result, parent: parent, context: context
        ).as(MemberAccessExprSyntax.self) {
            result = next
        }
    }

    // RedundantStaticSelf
    if context.shouldFormat(RedundantStaticSelf.self, node: Syntax(result)) {
        if let next = RedundantStaticSelf.transform(
            result, parent: parent, context: context
        ).as(MemberAccessExprSyntax.self) {
            result = next
        }
    }

    // NoForceUnwrap — unported (file-level pre-scan, instance state).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    return result
}
