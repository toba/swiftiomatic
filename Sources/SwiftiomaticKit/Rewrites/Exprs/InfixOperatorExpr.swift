import SwiftSyntax

/// Compact-pipeline merge of all `InfixOperatorExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteInfixOperatorExpr(
    _ node: InfixOperatorExprSyntax,
    context: Context
) -> InfixOperatorExprSyntax {
    var result = node
    let parent: Syntax? = nil

    // NoAssignmentInExpressions
    if context.shouldFormat(NoAssignmentInExpressions.self, node: Syntax(result)) {
        if let next = NoAssignmentInExpressions.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // NoYodaConditions
    if context.shouldFormat(NoYodaConditions.self, node: Syntax(result)) {
        if let next = NoYodaConditions.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // PreferCompoundAssignment
    if context.shouldFormat(PreferCompoundAssignment.self, node: Syntax(result)) {
        if let next = PreferCompoundAssignment.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // PreferIsEmpty
    if context.shouldFormat(PreferIsEmpty.self, node: Syntax(result)) {
        if let next = PreferIsEmpty.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // PreferToggle
    if context.shouldFormat(PreferToggle.self, node: Syntax(result)) {
        if let next = PreferToggle.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // RedundantNilCoalescing
    if context.shouldFormat(RedundantNilCoalescing.self, node: Syntax(result)) {
        if let next = RedundantNilCoalescing.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    // WrapConditionalAssignment
    if context.shouldFormat(WrapConditionalAssignment.self, node: Syntax(result)) {
        if let next = WrapConditionalAssignment.transform(
            result, parent: parent, context: context
        ).as(InfixOperatorExprSyntax.self) {
            result = next
        }
    }

    return result
}
