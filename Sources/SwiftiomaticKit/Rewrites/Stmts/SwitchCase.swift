import SwiftSyntax

/// Compact-pipeline merge of all `SwitchCaseSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteSwitchCase(
    _ node: SwitchCaseSyntax,
    parent: Syntax?,
    context: Context
) -> SwitchCaseSyntax {
    var result = node
    // RedundantBreak
    if context.shouldRewrite(RedundantBreak.self, at: Syntax(result)) {
        result = RedundantBreak.transform(result, parent: parent, context: context)
    }

    // WrapSwitchCaseBodies
    if context.shouldRewrite(WrapSwitchCaseBodies.self, at: Syntax(result)) {
        result = WrapSwitchCaseBodies.transform(result, parent: parent, context: context)
    }

    // BlankLinesBeforeControlFlowBlocks — inserts a blank line before
    // multi-line control-flow statements within a case body.
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(result)) {
        if let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
            in: Array(result.statements),
            context: context
        ) {
            result.statements = CodeBlockItemListSyntax(updated)
        }
    }

    return result
}
