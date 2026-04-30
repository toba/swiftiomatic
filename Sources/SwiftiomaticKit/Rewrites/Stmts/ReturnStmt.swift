import SwiftSyntax

/// Compact-pipeline merge of all `ReturnStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// No node-local rules currently target `ReturnStmtSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteReturnStmt(
    _ node: ReturnStmtSyntax,
    parent: Syntax?,
    context: Context
) -> ReturnStmtSyntax {
    var result = node

    // NoParensAroundConditions — strips parens around a return value and
    // ensures `return` keyword has a trailing space.
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)),
       let expression = result.expression,
       let stripped = NoParensAroundConditions.minimalSingleExpression(expression, context: context)
    {
        result.expression = stripped
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.returnKeyword.trailingTrivia)
    }

    return result
}
