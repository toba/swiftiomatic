import SwiftSyntax

/// Compact-pipeline merge of all `ActorDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteActorDecl(
    _ node: ActorDeclSyntax,
    parent: Syntax?,
    context: Context
) -> ActorDeclSyntax {
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
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, context: context,
        transform: SimplifyGenericConstraints.transform
    )

    // RedundantSwiftTestingSuite — strip a no-argument `@Suite` attribute
    // when `import Testing` is present.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result)) {
        result = RedundantSwiftTestingSuite.removeSuite(
            from: result, keyword: \.actorKeyword, context: context
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
