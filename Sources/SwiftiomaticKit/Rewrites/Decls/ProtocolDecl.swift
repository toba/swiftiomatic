import SwiftSyntax

/// Compact-pipeline merge of all `ProtocolDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteProtocolDecl(
    _ node: ProtocolDeclSyntax,
    context: Context
) -> ProtocolDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching ProtocolDeclSyntax — tracked for sub-issue 4f:
    //   - PreferAnyObject (no static transform)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(PreferAnyObject.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
