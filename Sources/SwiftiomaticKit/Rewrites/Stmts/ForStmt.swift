import SwiftSyntax

/// Compact-pipeline merge of all `ForStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
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

    // WrapSingleLineBodies — wrap or inline single-statement for body.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
