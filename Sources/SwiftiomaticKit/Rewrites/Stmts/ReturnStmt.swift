import SwiftSyntax

/// Compact-pipeline merge of all `ReturnStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// No node-local rules currently target `ReturnStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteReturnStmt(
    _ node: ReturnStmtSyntax,
    context: Context
) -> ReturnStmtSyntax {
    var result = node
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // NoParensAroundConditions — unported (legacy `SyntaxFormatRule.visit`
    // override across multiple statement node types). Audit-only
    // `shouldFormat` call preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result))

    return result
}
