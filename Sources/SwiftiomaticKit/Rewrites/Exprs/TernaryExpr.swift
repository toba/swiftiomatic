import SwiftSyntax

/// Compact-pipeline merge of all `TernaryExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
func rewriteTernaryExpr(
    _ node: TernaryExprSyntax,
    parent: Syntax?,
    context: Context
) -> TernaryExprSyntax {
    var result = node

    applyRule(
        NoVoidTernary.self, to: &result,
        parent: parent, context: context,
        transform: NoVoidTernary.transform
    )

    applyRule(
        WrapTernary.self, to: &result,
        parent: parent, context: context,
        transform: WrapTernary.transform
    )

    return result
}
