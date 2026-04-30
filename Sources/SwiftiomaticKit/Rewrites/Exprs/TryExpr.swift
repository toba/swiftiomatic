import SwiftSyntax

/// Compact-pipeline merge of all `TryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteTryExpr(
    _ node: TryExprSyntax,
    parent: Syntax?,
    context: Context
) -> TryExprSyntax {
    var result = node
    // No ported rules currently register `static transform` for TryExprSyntax.

    // NoForceTry — diagnose / rewrite `try!` based on the current scope
    // state (test function vs. non-test vs. inside closure).
    if context.shouldRewrite(NoForceTry.self, at: Syntax(result)) {
        result = NoForceTry.rewriteTryExpr(result, context: context)
    }

    return result
}
