import SwiftSyntax

/// Compact-pipeline merge of all `InitializerClauseSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteInitializerClause(
    _ node: InitializerClauseSyntax,
    parent: Syntax?,
    context: Context
) -> InitializerClauseSyntax {
    var result = node

    // NoParensAroundConditions — strips parens around an initializer's
    // value (e.g. `let x = (foo)` → `let x = foo`).
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)),
       let stripped = NoParensAroundConditions.minimalSingleExpression(result.value, context: context)
    {
        result.value = stripped
    }

    return result
}
