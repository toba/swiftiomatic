import SwiftSyntax

/// Compact-pipeline merge of all `EnumDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteEnumDecl(
    _ node: EnumDeclSyntax,
    parent: Syntax?,
    context: Context
) -> EnumDeclSyntax {
    var result = node

    applyRule(
        CollapseSimpleEnums.self, to: &result,
        parent: parent, context: context,
        transform: CollapseSimpleEnums.transform
    )

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        IndirectEnum.self, to: &result,
        parent: parent, context: context,
        transform: IndirectEnum.transform
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
        OneDeclarationPerLine.self, to: &result,
        parent: parent, context: context,
        transform: OneDeclarationPerLine.transform
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
        RedundantSendable.self, to: &result,
        parent: parent, context: context,
        transform: RedundantSendable.transform
    )

    applyRule(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, context: context,
        transform: SimplifyGenericConstraints.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    applyRule(
        ValidateTestCases.self, to: &result,
        parent: parent, context: context,
        transform: ValidateTestCases.transform
    )

    // RedundantSwiftTestingSuite — strip a no-argument `@Suite` attribute
    // when `import Testing` is present.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result)) {
        result = RedundantSwiftTestingSuite.removeSuite(
            from: result, keyword: \.enumKeyword, context: context
        )
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    return result
}
