import SwiftSyntax

/// Compact-pipeline merge of all `RepeatStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
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
    // and ensures `while` keyword has a trailing space. Helpers in
    // `NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        if let stripped = noParensMinimalSingleExpression(result.condition, context: context) {
            result.condition = stripped
            noParensFixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
        }
    }

    // WrapSingleLineBodies — wrap or inline single-statement repeat body.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
