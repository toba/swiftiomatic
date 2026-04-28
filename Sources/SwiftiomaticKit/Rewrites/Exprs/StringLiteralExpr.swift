import SwiftSyntax

/// Compact-pipeline merge of all `StringLiteralExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteStringLiteralExpr(
    _ node: StringLiteralExprSyntax,
    parent: Syntax?,
    context: Context
) -> StringLiteralExprSyntax {
    let result = node

    // NoForceUnwrap — string-interpolation depth tracked via
    // generator-emitted `willEnter`/`didExit` hooks; no transform here.

    return result
}
