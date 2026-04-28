import SwiftSyntax

/// Compact-pipeline merge of all `TernaryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteTernaryExpr(
    _ node: TernaryExprSyntax,
    context: Context
) -> TernaryExprSyntax {
    var result = node
    let parent: Syntax? = nil

    // NoVoidTernary
    if context.shouldFormat(NoVoidTernary.self, node: Syntax(result)) {
        if let next = NoVoidTernary.transform(
            result, parent: parent, context: context
        ).as(TernaryExprSyntax.self) {
            result = next
        }
    }

    // WrapTernary
    if context.shouldFormat(WrapTernary.self, node: Syntax(result)) {
        if let next = WrapTernary.transform(
            result, parent: parent, context: context
        ).as(TernaryExprSyntax.self) {
            result = next
        }
    }

    return result
}
