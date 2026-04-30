import SwiftSyntax

/// Compact-pipeline merge of all `DeinitializerDeclSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteDeinitializerDecl(
    _ node: DeinitializerDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeinitializerDeclSyntax {
    var result = node

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    // Unported rules touching DeinitializerDeclSyntax — tracked for sub-issue 4f:    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    return result
}
