import SwiftSyntax

/// Compact-pipeline merge of all `IsExprSyntax` rewrites. Each former rule's
/// logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteIsExpr(
    _ node: IsExprSyntax,
    parent: Syntax?,
    context: Context
) -> IsExprSyntax {
    let result = node

    // No ported rules currently register `static transform` for
    // IsExprSyntax. Generator-emitted hooks only.

    return result
}
