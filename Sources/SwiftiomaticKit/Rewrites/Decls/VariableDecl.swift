import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `VariableDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteVariableDecl(
    _ node: VariableDeclSyntax,
    context: Context
) -> VariableDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // AvoidNoneName
    if context.shouldFormat(AvoidNoneName.self, node: Syntax(result)) {
        if let next = AvoidNoneName.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // PrivateStateVariables
    if context.shouldFormat(PrivateStateVariables.self, node: Syntax(result)) {
        if let next = PrivateStateVariables.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantNilInit
    if context.shouldFormat(RedundantNilInit.self, node: Syntax(result)) {
        if let next = RedundantNilInit.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantPattern
    if context.shouldFormat(RedundantPattern.self, node: Syntax(result)) {
        if let next = RedundantPattern.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSetterACL
    if context.shouldFormat(RedundantSetterACL.self, node: Syntax(result)) {
        if let next = RedundantSetterACL.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantType
    if context.shouldFormat(RedundantType.self, node: Syntax(result)) {
        if let next = RedundantType.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantViewBuilder
    if context.shouldFormat(RedundantViewBuilder.self, node: Syntax(result)) {
        if let next = RedundantViewBuilder.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching VariableDeclSyntax — tracked for sub-issue 4f:
    //   - StrongOutlets (no static transform)
    _ = context.shouldFormat(StrongOutlets.self, node: Syntax(result))

    return result
}
