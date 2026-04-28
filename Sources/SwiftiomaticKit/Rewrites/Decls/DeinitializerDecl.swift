import SwiftSyntax

/// Compact-pipeline merge of all `DeinitializerDeclSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteDeinitializerDecl(
    _ node: DeinitializerDeclSyntax,
    context: Context
) -> DeinitializerDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(DeinitializerDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(DeinitializerDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching DeinitializerDeclSyntax — tracked for sub-issue 4f:
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
