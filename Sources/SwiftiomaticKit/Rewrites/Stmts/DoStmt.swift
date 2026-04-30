import SwiftSyntax

/// Compact-pipeline merge of all `DoStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// No node-local rules currently target `DoStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteDoStmt(
    _ node: DoStmtSyntax,
    parent: Syntax?,
    context: Context
) -> DoStmtSyntax {
    var result = node

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    return result
}
