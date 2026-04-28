import SwiftSyntax

/// Compact-pipeline merge of all `ForceUnwrapExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteForceUnwrapExpr(
    _ node: ForceUnwrapExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    applyRule(
        URLMacro.self, to: &result,
        parent: parent, context: context,
        transform: URLMacro.transform
    )

    // NoForceUnwrap — chain-top wrapping in test functions.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        return noForceUnwrapRewriteForceUnwrap(result, context: context)
    }

    return ExprSyntax(result)
}
