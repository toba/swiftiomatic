import SwiftSyntax

/// Compact-pipeline merge of all `TryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteTryExpr(
    _ node: TryExprSyntax,
    parent: Syntax?,
    context: Context
) -> TryExprSyntax {
    var result = node
    // No ported rules currently register `static transform` for TryExprSyntax.

    // NoForceTry — diagnose / rewrite `try!` based on the current scope
    // state (test function vs. non-test vs. inside closure). Helpers in
    // `NoForceTryHelpers.swift`.
    if context.shouldFormat(NoForceTry.self, node: Syntax(result)) {
        result = noForceTryRewriteTryExpr(result, context: context)
    }

    return result
}
