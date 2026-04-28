import SwiftSyntax

/// Compact-pipeline merge of all `InitializerDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteInitializerDecl(
    _ node: InitializerDeclSyntax,
    parent: Syntax?,
    context: Context
) -> InitializerDeclSyntax {
    var result = node

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        InitCoderUnavailable.self, to: &result,
        parent: parent, context: context,
        transform: InitCoderUnavailable.transform
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

    // RedundantEscaping — strip redundant `@escaping` from non-escaping
    // closure parameters.
    applyRule(
        RedundantEscaping.self, to: &result,
        parent: parent, context: context,
        transform: RedundantEscaping.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    return result
}
