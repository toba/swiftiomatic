import SwiftSyntax

/// Compact-pipeline merge of all `FunctionTypeSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteFunctionType(
    _ node: FunctionTypeSyntax,
    context: Context
) -> FunctionTypeSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // RedundantTypedThrows
    if context.shouldFormat(RedundantTypedThrows.self, node: Syntax(result)) {
        if let next = RedundantTypedThrows.transform(
            result, parent: parent, context: context
        ).as(FunctionTypeSyntax.self) {
            result = next
        }
    }

    // PreferVoidReturn — unported (legacy `SyntaxFormatRule.visit` override).
    // Audit-only `shouldFormat` call preserves rule-mask gating; deferred to
    // 4f.
    _ = context.shouldFormat(PreferVoidReturn.self, node: Syntax(result))

    return result
}
