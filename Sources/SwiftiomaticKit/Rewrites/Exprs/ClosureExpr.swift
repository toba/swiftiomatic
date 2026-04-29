import SwiftSyntax

/// Compact-pipeline merge of all `ClosureExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// `willEnter`/`didExit` hooks (e.g. `RedundantSelf`) are emitted by the
/// generator before/after `super.visit`, not from inside this function.
func rewriteClosureExpr(
    _ node: ClosureExprSyntax,
    parent: Syntax?,
    context: Context
) -> ClosureExprSyntax {
    var result = node

    applyRule(
        RedundantReturn.self, to: &result,
        parent: parent, context: context,
        transform: RedundantReturn.transform
    )

    applyRule(
        UnusedArguments.self, to: &result,
        parent: parent, context: context,
        transform: UnusedArguments.transform
    )

    // NoForceTry — closure depth tracked via generator-emitted
    // `willEnter`/`didExit` hooks; the rule's `TryExpr` handler bails out
    // when `closureDepth > 0` to match the legacy non-recursion behavior.

    // NoForceUnwrap — closure depth tracked via generator-emitted
    // `willEnter`/`didExit` hooks; no transform here.

    // NamedClosureParams — multi-line tracking handled by the
    // generator-emitted `willEnter(_ ClosureExpr)` / `didExit(_ ClosureExpr)`
    // hooks; the diagnose call lives in `rewriteDeclReferenceExpr`. Helpers
    // in `NamedClosureParamsHelpers.swift`.

    return result
}
