import SwiftSyntax

/// Compact-pipeline merge of all `ExtensionDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteExtensionDecl(
    _ node: ExtensionDeclSyntax,
    parent: Syntax?,
    context: Context
) -> ExtensionDeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        PreferAngleBracketExtensions.self, to: &result,
        parent: parent, transform: PreferAngleBracketExtensions.transform
    )

    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    // Unported rules touching ExtensionDeclSyntax — tracked for sub-issue 4f:    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    return result
}
