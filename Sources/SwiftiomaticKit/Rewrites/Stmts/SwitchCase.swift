import SwiftSyntax

/// Compact-pipeline merge of all `SwitchCaseSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteSwitchCase(
    _ node: SwitchCaseSyntax,
    context: Context
) -> SwitchCaseSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // RedundantBreak
    if context.shouldFormat(RedundantBreak.self, node: Syntax(result)) {
        result = RedundantBreak.transform(result, parent: parent, context: context)
    }

    // WrapSwitchCaseBodies
    if context.shouldFormat(WrapSwitchCaseBodies.self, node: Syntax(result)) {
        result = WrapSwitchCaseBodies.transform(result, parent: parent, context: context)
    }

    // BlankLinesBeforeControlFlowBlocks — unported (legacy
    // `SyntaxFormatRule.visit` override; trivia handling not yet migrated
    // to a static `transform`). Audit-only `shouldFormat` call preserves
    // rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(BlankLinesBeforeControlFlowBlocks.self, node: Syntax(result))

    return result
}
