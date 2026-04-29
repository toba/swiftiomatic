import SwiftSyntax

/// Compact-pipeline merge of all `ConditionElementSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self,
/// node:)`.
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
    // expression form of a condition element.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)),
       case .expression(let condition) = result.condition,
       let stripped = NoParensAroundConditions.minimalSingleExpression(condition, context: context)
    {
        result.condition = .expression(stripped)
    }

    return result
}
