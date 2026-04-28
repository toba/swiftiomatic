import SwiftSyntax

/// Compact-pipeline merge of all `FunctionSignatureSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteFunctionSignature(
    _ node: FunctionSignatureSyntax,
    context: Context
) -> FunctionSignatureSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // No ported rules currently register `static transform` for
    // FunctionSignatureSyntax.

    // NoVoidReturnOnFunctionSignature — unported (legacy `SyntaxFormatRule`
    // visit override). Audit-only `shouldFormat` call preserves rule-mask
    // gating; deferred to 4f.
    _ = context.shouldFormat(NoVoidReturnOnFunctionSignature.self, node: Syntax(result))

    return result
}
