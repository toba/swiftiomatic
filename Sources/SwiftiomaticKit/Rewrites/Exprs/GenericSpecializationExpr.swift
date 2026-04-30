import SwiftSyntax

/// Compact-pipeline merge of all `GenericSpecializationExprSyntax` rewrites.
/// Each former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteGenericSpecializationExpr(
    _ node: GenericSpecializationExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result: ExprSyntax = ExprSyntax(node)

    // PreferShorthandTypeNames — `Array<T>()`/`Dictionary<K,V>()`/`Optional<T>()`
    // expression-context shorthand. May change the concrete expression kind.
    if context.shouldRewrite(PreferShorthandTypeNames.self, at: Syntax(result)),
       let typed = result.as(GenericSpecializationExprSyntax.self)
    {
        result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
    }

    return result
}
