import SwiftSyntax

/// Compact-pipeline merge of all `SwitchCaseSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteSwitchCase(
    _ node: SwitchCaseSyntax,
    parent: Syntax?,
    context: Context
) -> SwitchCaseSyntax {
    var result = node
    // RedundantBreak
    if context.shouldFormat(RedundantBreak.self, node: Syntax(result)) {
        result = RedundantBreak.transform(result, parent: parent, context: context)
    }

    // WrapSwitchCaseBodies
    if context.shouldFormat(WrapSwitchCaseBodies.self, node: Syntax(result)) {
        result = WrapSwitchCaseBodies.transform(result, parent: parent, context: context)
    }

    // BlankLinesBeforeControlFlowBlocks — inserts a blank line before
    // multi-line control-flow statements within a case body. Helpers in
    // `BlankLinesBeforeControlFlowHelpers.swift`.
    if context.shouldFormat(BlankLinesBeforeControlFlowBlocks.self, node: Syntax(result)) {
        if let updated = blankLinesBeforeControlFlowInsertBlankLines(
            in: Array(result.statements),
            context: context
        ) {
            result.statements = CodeBlockItemListSyntax(updated)
        }
    }

    return result
}
