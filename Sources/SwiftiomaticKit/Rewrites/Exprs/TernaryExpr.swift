import SwiftSyntax

/// Compact-pipeline merge of all `TernaryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteTernaryExpr(
    _ node: TernaryExprSyntax,
    parent: Syntax?,
    context: Context
) -> TernaryExprSyntax {
    var result = node

    context.applyRewrite(
        NoVoidTernary.self, to: &result,
        parent: parent, transform: NoVoidTernary.transform
    )

    context.applyRewrite(
        WrapTernary.self, to: &result,
        parent: parent, transform: WrapTernary.transform
    )

    return result
}
