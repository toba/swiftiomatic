import SwiftSyntax

/// Compact-pipeline merge of all `RepeatStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// No node-local rules currently target `RepeatStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteRepeatStmt(
    _ node: RepeatStmtSyntax,
    parent: Syntax?,
    context: Context
) -> RepeatStmtSyntax {
    var result = node
    // NoParensAroundConditions — strips parens around the `while` condition
    // and ensures `while` keyword has a trailing space.
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)) {
        if let stripped = NoParensAroundConditions.minimalSingleExpression(result.condition, context: context) {
            result.condition = stripped
            NoParensAroundConditions.fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
        }
    }

    // WrapSingleLineBodies — wrap or inline single-statement repeat body.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
