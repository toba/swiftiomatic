import SwiftSyntax

/// Compact-pipeline merge of all `StringLiteralExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
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
