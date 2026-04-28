import SwiftSyntax

/// Compact-pipeline merge of all `DeclReferenceExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteDeclReferenceExpr(
    _ node: DeclReferenceExprSyntax,
    context: Context
) -> DeclReferenceExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // No ported rules currently register `static transform` for
    // DeclReferenceExprSyntax.

    // NamedClosureParams — unported. Audit-only; deferred to 4f.
    _ = context.shouldFormat(NamedClosureParams.self, node: Syntax(result))

    return result
}
