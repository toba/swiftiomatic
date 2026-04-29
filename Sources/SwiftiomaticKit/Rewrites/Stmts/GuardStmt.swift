import SwiftSyntax

/// Compact-pipeline merge of all `GuardStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// No node-local rules currently target `GuardStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteGuardStmt(
    _ node: GuardStmtSyntax,
    parent: Syntax?,
    context: Context
) -> GuardStmtSyntax {
    var result = node
    // NoParensAroundConditions — ensures `guard` keyword has a trailing space
    // after paren-stripped conditions.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.guardKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement guard body. The
    // transform returns `StmtSyntax` but the underlying node remains a
    // `GuardStmtSyntax`, so `applyRule`'s cast-back succeeds.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
