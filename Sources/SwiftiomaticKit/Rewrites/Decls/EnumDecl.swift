import SwiftSyntax

/// Compact-pipeline merge of all `EnumDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteEnumDecl(
    _ node: EnumDeclSyntax,
    parent: Syntax?,
    context: Context
) -> EnumDeclSyntax {
    var result = node

    context.applyRewrite(
        CollapseSimpleEnums.self, to: &result,
        parent: parent, transform: CollapseSimpleEnums.transform
    )

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        IndirectEnum.self, to: &result,
        parent: parent, transform: IndirectEnum.transform
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
        OneDeclarationPerLine.self, to: &result,
        parent: parent, transform: OneDeclarationPerLine.transform
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
        RedundantSendable.self, to: &result,
        parent: parent, transform: RedundantSendable.transform
    )

    context.applyRewrite(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, transform: SimplifyGenericConstraints.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    context.applyRewrite(
        ValidateTestCases.self, to: &result,
        parent: parent, transform: ValidateTestCases.transform
    )

    // RedundantSwiftTestingSuite — strip a no-argument `@Suite` attribute
    // when `import Testing` is present.
    if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(result)) {
        result = RedundantSwiftTestingSuite.removeSuite(
            from: result, keyword: \.enumKeyword, context: context
        )
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    return result
}
