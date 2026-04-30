import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptCallExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteSubscriptCallExpr(
    _ node: SubscriptCallExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    let result = node

    // NoForceUnwrap — chain-top wrapping. Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)) {
        return NoForceUnwrap.rewriteSubscriptCallTop(result, context: context)
    }

    return ExprSyntax(result)
}
