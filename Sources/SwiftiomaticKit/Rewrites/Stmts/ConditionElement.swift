import SwiftSyntax

/// Compact-pipeline merge of all `ConditionElementSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self,
/// node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteConditionElement(
    _ node: ConditionElementSyntax,
    context: Context
) -> ConditionElementSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // ExplicitNilCheck
    if context.shouldFormat(ExplicitNilCheck.self, node: Syntax(result)) {
        result = ExplicitNilCheck.transform(result, parent: parent, context: context)
    }

    // NoParensAroundConditions — unported (legacy `SyntaxFormatRule.visit`
    // override across multiple statement node types). Audit-only
    // `shouldFormat` call preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result))

    return result
}
