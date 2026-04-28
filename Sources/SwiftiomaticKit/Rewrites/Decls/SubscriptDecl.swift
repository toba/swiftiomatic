import SwiftSyntax

/// Compact-pipeline merge of all `SubscriptDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteSubscriptDecl(
    _ node: SubscriptDeclSyntax,
    context: Context
) -> SubscriptDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // OpaqueGenericParameters
    if context.shouldFormat(OpaqueGenericParameters.self, node: Syntax(result)) {
        if let next = OpaqueGenericParameters.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // RedundantReturn
    if context.shouldFormat(RedundantReturn.self, node: Syntax(result)) {
        if let next = RedundantReturn.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // UnusedArguments
    if context.shouldFormat(UnusedArguments.self, node: Syntax(result)) {
        if let next = UnusedArguments.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    // UseImplicitInit
    if context.shouldFormat(UseImplicitInit.self, node: Syntax(result)) {
        if let next = UseImplicitInit.transform(
            result, parent: parent, context: context
        ).as(SubscriptDeclSyntax.self) {
            result = next
        }
    }

    return result
}
