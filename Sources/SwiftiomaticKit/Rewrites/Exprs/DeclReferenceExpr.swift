import SwiftSyntax

/// Compact-pipeline merge of all `DeclReferenceExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
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
    if context.shouldRewrite(NamedClosureParams.self, at: Syntax(result)) {
        NamedClosureParams.rewriteDeclReference(result, context: context)
    }

    return result
}
