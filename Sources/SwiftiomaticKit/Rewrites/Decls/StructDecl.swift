import SwiftSyntax

/// Compact-pipeline merge of all `StructDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteStructDecl(
    _ node: StructDeclSyntax,
    context: Context
) -> StructDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // RedundantEquatable
    if context.shouldFormat(RedundantEquatable.self, node: Syntax(result)) {
        if let next = RedundantEquatable.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSendable
    if context.shouldFormat(RedundantSendable.self, node: Syntax(result)) {
        if let next = RedundantSendable.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // SimplifyGenericConstraints
    if context.shouldFormat(SimplifyGenericConstraints.self, node: Syntax(result)) {
        if let next = SimplifyGenericConstraints.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // StaticStructShouldBeEnum
    if context.shouldFormat(StaticStructShouldBeEnum.self, node: Syntax(result)) {
        if let next = StaticStructShouldBeEnum.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // TestSuiteAccessControl
    if context.shouldFormat(TestSuiteAccessControl.self, node: Syntax(result)) {
        if let next = TestSuiteAccessControl.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // ValidateTestCases
    if context.shouldFormat(ValidateTestCases.self, node: Syntax(result)) {
        if let next = ValidateTestCases.transform(
            result, parent: parent, context: context
        ).as(StructDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching StructDeclSyntax — tracked for sub-issue 4f:
    //   - RedundantSwiftTestingSuite (instance state)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
