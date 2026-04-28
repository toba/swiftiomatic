import SwiftSyntax

/// Compact-pipeline merge of all `EnumDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteEnumDecl(
    _ node: EnumDeclSyntax,
    context: Context
) -> EnumDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // CollapseSimpleEnums
    if context.shouldFormat(CollapseSimpleEnums.self, node: Syntax(result)) {
        if let next = CollapseSimpleEnums.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // IndirectEnum
    if context.shouldFormat(IndirectEnum.self, node: Syntax(result)) {
        if let next = IndirectEnum.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // OneDeclarationPerLine
    if context.shouldFormat(OneDeclarationPerLine.self, node: Syntax(result)) {
        if let next = OneDeclarationPerLine.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSendable
    if context.shouldFormat(RedundantSendable.self, node: Syntax(result)) {
        if let next = RedundantSendable.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // SimplifyGenericConstraints
    if context.shouldFormat(SimplifyGenericConstraints.self, node: Syntax(result)) {
        if let next = SimplifyGenericConstraints.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // ValidateTestCases
    if context.shouldFormat(ValidateTestCases.self, node: Syntax(result)) {
        if let next = ValidateTestCases.transform(
            result, parent: parent, context: context
        ).as(EnumDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching EnumDeclSyntax — tracked for sub-issue 4f:
    //   - RedundantSwiftTestingSuite (instance state)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
