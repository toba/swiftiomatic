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
    context: Context
) -> ForceUnwrapExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // URLMacro
    if context.shouldFormat(URLMacro.self, node: Syntax(result)) {
        if let next = URLMacro.transform(
            result, parent: parent, context: context
        ).as(ForceUnwrapExprSyntax.self) {
            result = next
        }
    }

    // NoForceUnwrap — unported (file-level pre-scan, instance state).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    return result
}
