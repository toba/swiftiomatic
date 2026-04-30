import SwiftSyntax

/// Compact-pipeline merge of all `GuardStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
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
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.guardKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement guard body. The
    // transform returns `StmtSyntax` but the underlying node remains a
    // `GuardStmtSyntax`, so `applyRule`'s cast-back succeeds.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
