import SwiftSyntax

/// Compact-pipeline merge of all `WhileStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
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
    // space after paren-stripped conditions. Helpers in
    // `NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        noParensFixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement while body.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
