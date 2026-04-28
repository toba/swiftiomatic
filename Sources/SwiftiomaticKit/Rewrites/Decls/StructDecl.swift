import SwiftSyntax

/// Compact-pipeline merge of all `StructDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Returns `DeclSyntax` so `StaticStructShouldBeEnum` can widen the node to an
/// `EnumDeclSyntax`. All preceding rules preserve the `StructDeclSyntax` kind;
/// the kind-widening rule runs last and short-circuits any further work.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteStructDecl(
    _ node: StructDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeclSyntax {
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
        RedundantAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAccessControl.transform
    )

    applyRule(
        RedundantEquatable.self, to: &result,
        parent: parent, context: context,
        transform: RedundantEquatable.transform
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
        TestSuiteAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: TestSuiteAccessControl.transform
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
    // when `import Testing` is present. Helpers in
    // `RedundantSwiftTestingSuiteHelpers.swift`.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result)) {
        result = redundantSwiftTestingSuiteRemoveSuite(
            from: result, keyword: \.structKeyword, context: context
        )
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // StaticStructShouldBeEnum — runs last because it can widen the node from
    // `StructDeclSyntax` to `EnumDeclSyntax`. Subsequent rules in this function
    // are all StructDecl-typed, so this must come after them.
    if context.shouldFormat(StaticStructShouldBeEnum.self, node: Syntax(result)) {
        return StaticStructShouldBeEnum.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}
