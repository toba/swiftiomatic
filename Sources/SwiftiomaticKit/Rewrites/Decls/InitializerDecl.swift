import SwiftSyntax

/// Compact-pipeline merge of all `InitializerDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteInitializerDecl(
    _ node: InitializerDeclSyntax,
    context: Context
) -> InitializerDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // InitCoderUnavailable
    if context.shouldFormat(InitCoderUnavailable.self, node: Syntax(result)) {
        if let next = InitCoderUnavailable.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // OpaqueGenericParameters
    if context.shouldFormat(OpaqueGenericParameters.self, node: Syntax(result)) {
        if let next = OpaqueGenericParameters.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // UnusedArguments
    if context.shouldFormat(UnusedArguments.self, node: Syntax(result)) {
        if let next = UnusedArguments.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // UseImplicitInit
    if context.shouldFormat(UseImplicitInit.self, node: Syntax(result)) {
        if let next = UseImplicitInit.transform(
            result, parent: parent, context: context
        ).as(InitializerDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching InitializerDeclSyntax — tracked for sub-issue 4f:
    //   - RedundantEscaping (no static transform)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(RedundantEscaping.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
