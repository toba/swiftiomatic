import SwiftSyntax

/// Compact-pipeline merge of all `IfExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteIfExpr(
    _ node: IfExprSyntax,
    parent: Syntax?,
    context: Context
) -> IfExprSyntax {
    var result = node
    context.applyRewrite(
        CollapseSimpleIfElse.self, to: &result,
        parent: parent, transform: CollapseSimpleIfElse.transform
    )

    context.applyRewrite(
        PreferUnavailable.self, to: &result,
        parent: parent, transform: PreferUnavailable.transform
    )

    // NoParensAroundConditions — ensures `if` keyword has a trailing space
    // after a paren-stripped condition list. The actual paren stripping for
    // each ConditionElement happens in `rewriteConditionElement`.
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.ifKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement if body. The
    // transform returns `ExprSyntax`, but the underlying node remains an
    // `IfExprSyntax`, so `applyRule`'s cast-back succeeds.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
