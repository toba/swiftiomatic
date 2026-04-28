import SwiftSyntax

/// Compact-pipeline merge of all `CodeBlockSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// No node-local rules currently target `CodeBlockSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteCodeBlock(
    _ node: CodeBlockSyntax,
    context: Context
) -> CodeBlockSyntax {
    var result = node
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // BlankLinesAfterGuardStatements — unported (legacy
    // `SyntaxFormatRule.visit` override; needs trivia handling migrated to
    // a static `transform`). Audit-only `shouldFormat` call preserves
    // rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(BlankLinesAfterGuardStatements.self, node: Syntax(result))

    // BlankLinesBeforeControlFlowBlocks — unported (same reasons as above).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(BlankLinesBeforeControlFlowBlocks.self, node: Syntax(result))

    return result
}
