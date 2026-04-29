import SwiftSyntax

/// Compact-pipeline merge of all `IfExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
func rewriteIfExpr(
    _ node: IfExprSyntax,
    parent: Syntax?,
    context: Context
) -> IfExprSyntax {
    var result = node
    applyRule(
        CollapseSimpleIfElse.self, to: &result,
        parent: parent, context: context,
        transform: CollapseSimpleIfElse.transform
    )

    applyRule(
        PreferUnavailable.self, to: &result,
        parent: parent, context: context,
        transform: PreferUnavailable.transform
    )

    // NoParensAroundConditions — ensures `if` keyword has a trailing space
    // after a paren-stripped condition list. The actual paren stripping for
    // each ConditionElement happens in `rewriteConditionElement`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&result.ifKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement if body. The
    // transform returns `ExprSyntax`, but the underlying node remains an
    // `IfExprSyntax`, so `applyRule`'s cast-back succeeds.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
