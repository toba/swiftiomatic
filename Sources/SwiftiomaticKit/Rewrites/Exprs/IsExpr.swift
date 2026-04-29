import SwiftSyntax

/// Compact-pipeline merge of all `IsExprSyntax` rewrites. Each former rule's
/// logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
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
