import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteSubscriptDecl(
    _ node: SubscriptDeclSyntax,
    parent: Syntax?,
    context: Context
) -> SubscriptDeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        ModifierOrder.self, to: &result,
        parent: parent, transform: ModifierOrder.transform
    )

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        OpaqueGenericParameters.self, to: &result,
        parent: parent, transform: OpaqueGenericParameters.transform
    )

    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        RedundantObjc.self, to: &result,
        parent: parent, transform: RedundantObjc.transform
    )

    context.applyRewrite(
        RedundantReturn.self, to: &result,
        parent: parent, transform: RedundantReturn.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    context.applyRewrite(
        UnusedArguments.self, to: &result,
        parent: parent, transform: UnusedArguments.transform
    )

    context.applyRewrite(
        UseImplicitInit.self, to: &result,
        parent: parent, transform: UseImplicitInit.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement subscript getter.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
