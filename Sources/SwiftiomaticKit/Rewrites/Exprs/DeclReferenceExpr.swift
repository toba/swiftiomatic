import SwiftSyntax

/// Compact-pipeline merge of all `DeclReferenceExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
func rewriteDeclReferenceExpr(
    _ node: DeclReferenceExprSyntax,
    parent: Syntax?,
    context: Context
) -> DeclReferenceExprSyntax {
    let result = node

    // No ported rules currently register `static transform` for
    // DeclReferenceExprSyntax.

    // NamedClosureParams — diagnose `$N` references inside multi-line
    // closures. Closure depth/multi-line tracking happens in
    // `NamedClosureParams.willEnter`/`didExit` on `ClosureExpr`.
    if context.shouldFormat(NamedClosureParams.self, node: Syntax(result)) {
        NamedClosureParams.rewriteDeclReference(result, context: context)
    }

    return result
}
