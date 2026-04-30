import SwiftSyntax

/// Compact-pipeline merge of all `StructDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
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
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        RedundantEquatable.self, to: &result,
        parent: parent, transform: RedundantEquatable.transform
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
        TestSuiteAccessControl.self, to: &result,
        parent: parent, transform: TestSuiteAccessControl.transform
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
            from: result, keyword: \.structKeyword, context: context
        )
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // StaticStructShouldBeEnum — runs last because it can widen the node from
    // `StructDeclSyntax` to `EnumDeclSyntax`. Subsequent rules in this function
    // are all StructDecl-typed, so this must come after them.
    if context.shouldRewrite(StaticStructShouldBeEnum.self, at: Syntax(result)) {
        return StaticStructShouldBeEnum.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}
