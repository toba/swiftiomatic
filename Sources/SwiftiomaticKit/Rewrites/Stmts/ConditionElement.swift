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
    parent: Syntax?,
    context: Context
) -> ConditionElementSyntax {
    var result = node
    // ExplicitNilCheck
    if context.shouldFormat(ExplicitNilCheck.self, node: Syntax(result)) {
        result = ExplicitNilCheck.transform(result, parent: parent, context: context)
    }

    // NoParensAroundConditions — strips redundant parens around the
    // expression form of a condition element. Helpers in
    // `NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)),
       case .expression(let condition) = result.condition,
       let stripped = noParensMinimalSingleExpression(condition, context: context)
    {
        result.condition = .expression(stripped)
    }

    return result
}
