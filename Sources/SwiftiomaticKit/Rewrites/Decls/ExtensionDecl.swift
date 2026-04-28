import SwiftSyntax

/// Compact-pipeline merge of all `ExtensionDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteExtensionDecl(
    _ node: ExtensionDeclSyntax,
    context: Context
) -> ExtensionDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(ExtensionDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ExtensionDeclSyntax.self) {
            result = next
        }
    }

    // PreferAngleBracketExtensions
    if context.shouldFormat(PreferAngleBracketExtensions.self, node: Syntax(result)) {
        if let next = PreferAngleBracketExtensions.transform(
            result, parent: parent, context: context
        ).as(ExtensionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(ExtensionDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(ExtensionDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching ExtensionDeclSyntax — tracked for sub-issue 4f:
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
