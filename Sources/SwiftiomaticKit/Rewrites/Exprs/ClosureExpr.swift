import SwiftSyntax

/// Compact-pipeline merge of all `ClosureExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// `willEnter`/`didExit` hooks (e.g. `RedundantSelf`) are emitted by the
/// generator before/after `super.visit`, not from inside this function.
func rewriteClosureExpr(
    _ node: ClosureExprSyntax,
    context: Context
) -> ClosureExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // RedundantReturn
    if context.shouldFormat(RedundantReturn.self, node: Syntax(result)) {
        if let next = RedundantReturn.transform(
            result, parent: parent, context: context
        ).as(ClosureExprSyntax.self) {
            result = next
        }
    }

    // UnusedArguments
    if context.shouldFormat(UnusedArguments.self, node: Syntax(result)) {
        if let next = UnusedArguments.transform(
            result, parent: parent, context: context
        ).as(ClosureExprSyntax.self) {
            result = next
        }
    }

    // NoForceTry / NoForceUnwrap — unported (file-level pre-scan, instance
    // state). Audit-only `shouldFormat` calls preserve rule-mask gating;
    // deferred to 4f.
    _ = context.shouldFormat(NoForceTry.self, node: Syntax(result))
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    // NamedClosureParams — unported. Audit-only; deferred to 4f.
    _ = context.shouldFormat(NamedClosureParams.self, node: Syntax(result))

    return result
}
