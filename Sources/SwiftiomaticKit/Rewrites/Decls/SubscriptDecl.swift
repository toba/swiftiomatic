import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteSubscriptDecl(
    _ node: SubscriptDeclSyntax,
    parent: Syntax?,
    context: Context
) -> SubscriptDeclSyntax {
    var result = node

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        ModifierOrder.self, to: &result,
        parent: parent, context: context,
        transform: ModifierOrder.transform
    )

    applyRule(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, context: context,
        transform: ModifiersOnSameLine.transform
    )

    applyRule(
        OpaqueGenericParameters.self, to: &result,
        parent: parent, context: context,
        transform: OpaqueGenericParameters.transform
    )

    applyRule(
        RedundantAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAccessControl.transform
    )

    applyRule(
        RedundantObjc.self, to: &result,
        parent: parent, context: context,
        transform: RedundantObjc.transform
    )

    applyRule(
        RedundantReturn.self, to: &result,
        parent: parent, context: context,
        transform: RedundantReturn.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    applyRule(
        UnusedArguments.self, to: &result,
        parent: parent, context: context,
        transform: UnusedArguments.transform
    )

    applyRule(
        UseImplicitInit.self, to: &result,
        parent: parent, context: context,
        transform: UseImplicitInit.transform
    )

    return result
}
