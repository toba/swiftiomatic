import SwiftSyntax

/// Compact-pipeline merge of all `IfExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteIfExpr(
    _ node: IfExprSyntax,
    context: Context
) -> IfExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // CollapseSimpleIfElse
    if context.shouldFormat(CollapseSimpleIfElse.self, node: Syntax(result)) {
        if let next = CollapseSimpleIfElse.transform(result, parent: parent, context: context).as(IfExprSyntax.self) {
            result = next
        }
    }

    // PreferUnavailable
    if context.shouldFormat(PreferUnavailable.self, node: Syntax(result)) {
        if let next = PreferUnavailable.transform(result, parent: parent, context: context).as(IfExprSyntax.self) {
            result = next
        }
    }

    // NoParensAroundConditions — unported (legacy `SyntaxFormatRule.visit`
    // override across multiple statement node types). Audit-only
    // `shouldFormat` call preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result))

    // WrapMultilineStatementBraces — unported (same reasons as above).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
