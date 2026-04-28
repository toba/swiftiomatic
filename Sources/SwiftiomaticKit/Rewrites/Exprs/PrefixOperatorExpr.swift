import SwiftSyntax

/// Compact-pipeline merge of all `PrefixOperatorExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewritePrefixOperatorExpr(
    _ node: PrefixOperatorExprSyntax,
    context: Context
) -> PrefixOperatorExprSyntax {
    var result = node
    let parent: Syntax? = nil

    // PreferExplicitFalse
    if context.shouldFormat(PreferExplicitFalse.self, node: Syntax(result)) {
        if let next = PreferExplicitFalse.transform(
            result, parent: parent, context: context
        ).as(PrefixOperatorExprSyntax.self) {
            result = next
        }
    }

    return result
}
