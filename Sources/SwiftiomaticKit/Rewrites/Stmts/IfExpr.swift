import SwiftSyntax

/// Compact-pipeline merge of all `IfExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
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
    // each ConditionElement happens in `rewriteConditionElement`. Helpers in
    // `NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        noParensFixKeywordTrailingTrivia(&result.ifKeyword.trailingTrivia)
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
