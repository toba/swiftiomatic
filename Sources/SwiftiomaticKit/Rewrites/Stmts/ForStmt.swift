import SwiftSyntax

/// Compact-pipeline merge of all `ForStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteForStmt(
    _ node: ForStmtSyntax,
    parent: Syntax?,
    context: Context
) -> ForStmtSyntax {
    var result = node

    applyRule(
        CaseLet.self, to: &result,
        parent: parent, context: context,
        transform: CaseLet.transform
    )

    applyRule(
        PreferWhereClausesInForLoops.self, to: &result,
        parent: parent, context: context,
        transform: PreferWhereClausesInForLoops.transform
    )

    applyRule(
        RedundantEnumerated.self, to: &result,
        parent: parent, context: context,
        transform: RedundantEnumerated.transform
    )

    applyRule(
        UnusedArguments.self, to: &result,
        parent: parent, context: context,
        transform: UnusedArguments.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    return result
}
