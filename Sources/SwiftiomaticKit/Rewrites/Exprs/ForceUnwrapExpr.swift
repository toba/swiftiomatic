import SwiftSyntax

/// Compact-pipeline merge of all `ForceUnwrapExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteForceUnwrapExpr(
    _ node: ForceUnwrapExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    // URLMacro — may widen `URL(string: "x")!` to `#URL("x")` (a
    // `MacroExpansionExprSyntax`). Direct dispatch with early return when
    // the kind changes.
    if context.shouldRewrite(URLMacro.self, at: Syntax(result)) {
        let widened = URLMacro.transform(result, parent: parent, context: context)
        if let stillForce = widened.as(ForceUnwrapExprSyntax.self) {
            result = stillForce
        } else {
            return widened
        }
    }

    // NoForceUnwrap — chain-top wrapping in test functions.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)) {
        return NoForceUnwrap.rewriteForceUnwrap(result, context: context)
    }

    return ExprSyntax(result)
}
