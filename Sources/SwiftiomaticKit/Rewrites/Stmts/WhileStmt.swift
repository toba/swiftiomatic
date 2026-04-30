import SwiftSyntax

/// Compact-pipeline merge of all `WhileStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// No node-local rules currently target `WhileStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteWhileStmt(
    _ node: WhileStmtSyntax,
    parent: Syntax?,
    context: Context
) -> WhileStmtSyntax {
    var result = node
    // NoParensAroundConditions — ensures `while` keyword has a trailing
    // space after paren-stripped conditions.
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement while body.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
