import SwiftSyntax

/// Compact-pipeline merge of all `InitializerDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteInitializerDecl(
    _ node: InitializerDeclSyntax,
    parent: Syntax?,
    context: Context
) -> InitializerDeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        InitCoderUnavailable.self, to: &result,
        parent: parent, transform: InitCoderUnavailable.transform
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

    // RedundantEscaping — strip redundant `@escaping` from non-escaping
    // closure parameters.
    context.applyRewrite(
        RedundantEscaping.self, to: &result,
        parent: parent, transform: RedundantEscaping.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement init body.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    return result
}
