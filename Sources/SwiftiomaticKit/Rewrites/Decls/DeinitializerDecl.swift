import SwiftSyntax

/// Compact-pipeline merge of all `DeinitializerDeclSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteDeinitializerDecl(
    _ node: DeinitializerDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeinitializerDeclSyntax {
    var result = node

    applyRule(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, context: context,
        transform: ModifiersOnSameLine.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    // Unported rules touching DeinitializerDeclSyntax — tracked for sub-issue 4f:    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    return result
}
