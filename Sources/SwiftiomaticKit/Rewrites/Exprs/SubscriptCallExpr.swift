import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptCallExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteSubscriptCallExpr(
    _ node: SubscriptCallExprSyntax,
    context: Context
) -> SubscriptCallExprSyntax {
    var result = node
    let parent: Syntax? = nil
    _ = parent
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // No ported rules currently register `static transform` for
    // SubscriptCallExprSyntax.

    // NoForceUnwrap — unported (file-level pre-scan, instance state).
    // Audit-only `shouldFormat` call preserves rule-mask gating; deferred
    // to 4f.
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    return result
}
