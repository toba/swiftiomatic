import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptCallExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteSubscriptCallExpr(
    _ node: SubscriptCallExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    let result = node

    // NoForceUnwrap — chain-top wrapping. Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        return noForceUnwrapRewriteSubscriptCallTop(result, context: context)
    }

    return ExprSyntax(result)
}
