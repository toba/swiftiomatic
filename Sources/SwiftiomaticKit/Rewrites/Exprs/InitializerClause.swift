import SwiftSyntax

/// Compact-pipeline merge of all `InitializerClauseSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteInitializerClause(
    _ node: InitializerClauseSyntax,
    parent: Syntax?,
    context: Context
) -> InitializerClauseSyntax {
    var result = node

    // NoParensAroundConditions — strips parens around an initializer's
    // value (e.g. `let x = (foo)` → `let x = foo`). Helpers in
    // `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)),
       let stripped = noParensMinimalSingleExpression(result.value, context: context)
    {
        result.value = stripped
    }

    return result
}
