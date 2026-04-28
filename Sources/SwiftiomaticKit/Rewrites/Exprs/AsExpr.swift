import SwiftSyntax

/// Compact-pipeline merge of all `AsExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteAsExpr(
    _ node: AsExprSyntax,
    context: Context
) -> AsExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // No ported rules currently register `static transform` for AsExprSyntax.

    // NoForceCast — unported (legacy `SyntaxFormatRule.visit` override not
    // yet migrated to a static `transform`). Audit-only `shouldFormat` call
    // preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(NoForceCast.self, node: Syntax(result))

    // NoForceUnwrap — unported (legacy `SyntaxFormatRule.visit` override
    // with file-level pre-scan state). Audit-only; deferred to 4f.
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    return result
}
