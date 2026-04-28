import SwiftSyntax

/// Compact-pipeline merge of all `ActorDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteActorDecl(
    _ node: ActorDeclSyntax,
    context: Context
) -> ActorDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(ActorDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(ActorDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ActorDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(ActorDeclSyntax.self) {
            result = next
        }
    }

    // SimplifyGenericConstraints
    if context.shouldFormat(SimplifyGenericConstraints.self, node: Syntax(result)) {
        if let next = SimplifyGenericConstraints.transform(
            result, parent: parent, context: context
        ).as(ActorDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching ActorDeclSyntax — tracked for sub-issue 4f:
    //   - RedundantSwiftTestingSuite (instance state, file-level pre-scan)
    //   - WrapMultilineStatementBraces (no static transform yet)
    _ = context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
