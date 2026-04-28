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
    parent: Syntax?,
    context: Context
) -> DeclReferenceExprSyntax {
    let result = node

    // No ported rules currently register `static transform` for
    // DeclReferenceExprSyntax.

    // NamedClosureParams — diagnose `$N` references inside multi-line
    // closures. Closure depth/multi-line tracking happens in the
    // generator-emitted `ClosureExpr` hooks. Helpers in
    // `NamedClosureParamsHelpers.swift`.
    if context.shouldFormat(NamedClosureParams.self, node: Syntax(result)) {
        namedClosureParamsRewriteDeclReference(result, context: context)
    }

    return result
}
