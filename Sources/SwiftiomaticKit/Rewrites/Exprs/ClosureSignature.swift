import SwiftSyntax

/// Compact-pipeline merge of all `ClosureSignatureSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteClosureSignature(
    _ node: ClosureSignatureSyntax,
    context: Context
) -> ClosureSignatureSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // NoParensInClosureParams
    if context.shouldFormat(NoParensInClosureParams.self, node: Syntax(result)) {
        result = NoParensInClosureParams.transform(result, parent: parent, context: context)
    }

    // PreferVoidReturn — unported (legacy `SyntaxFormatRule.visit` override
    // not yet migrated to a static `transform`). Audit-only `shouldFormat`
    // call preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(PreferVoidReturn.self, node: Syntax(result))

    return result
}
