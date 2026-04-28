import SwiftSyntax

/// Compact-pipeline merge of all `TernaryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteTernaryExpr(
    _ node: TernaryExprSyntax,
    parent: Syntax?,
    context: Context
) -> TernaryExprSyntax {
    var result = node

    applyRule(
        NoVoidTernary.self, to: &result,
        parent: parent, context: context,
        transform: NoVoidTernary.transform
    )

    applyRule(
        WrapTernary.self, to: &result,
        parent: parent, context: context,
        transform: WrapTernary.transform
    )

    return result
}
