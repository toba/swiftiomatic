import SwiftSyntax

/// Compact-pipeline merge of all `ForStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteForStmt(
    _ node: ForStmtSyntax,
    parent: Syntax?,
    context: Context
) -> ForStmtSyntax {
    var result = node

    context.applyRewrite(
        CaseLet.self, to: &result,
        parent: parent, transform: CaseLet.transform
    )

    context.applyRewrite(
        PreferWhereClausesInForLoops.self, to: &result,
        parent: parent, transform: PreferWhereClausesInForLoops.transform
    )

    context.applyRewrite(
        RedundantEnumerated.self, to: &result,
        parent: parent, transform: RedundantEnumerated.transform
    )

    context.applyRewrite(
        UnusedArguments.self, to: &result,
        parent: parent, transform: UnusedArguments.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement for body.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
