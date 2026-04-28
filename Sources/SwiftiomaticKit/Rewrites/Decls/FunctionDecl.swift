import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `FunctionDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteFunctionDecl(
    _ node: FunctionDeclSyntax,
    context: Context
) -> FunctionDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // NoExplicitOwnership
    if context.shouldFormat(NoExplicitOwnership.self, node: Syntax(result)) {
        if let next = NoExplicitOwnership.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // NoGuardInTests
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(result)) {
        if let next = NoGuardInTests.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // OpaqueGenericParameters
    if context.shouldFormat(OpaqueGenericParameters.self, node: Syntax(result)) {
        if let next = OpaqueGenericParameters.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAsync
    if context.shouldFormat(RedundantAsync.self, node: Syntax(result)) {
        if let next = RedundantAsync.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantReturn
    if context.shouldFormat(RedundantReturn.self, node: Syntax(result)) {
        if let next = RedundantReturn.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantThrows
    if context.shouldFormat(RedundantThrows.self, node: Syntax(result)) {
        if let next = RedundantThrows.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // RedundantViewBuilder
    if context.shouldFormat(RedundantViewBuilder.self, node: Syntax(result)) {
        if let next = RedundantViewBuilder.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // SimplifyGenericConstraints
    if context.shouldFormat(SimplifyGenericConstraints.self, node: Syntax(result)) {
        if let next = SimplifyGenericConstraints.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // SwiftTestingTestCaseNames
    if context.shouldFormat(SwiftTestingTestCaseNames.self, node: Syntax(result)) {
        if let next = SwiftTestingTestCaseNames.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // UnusedArguments
    if context.shouldFormat(UnusedArguments.self, node: Syntax(result)) {
        if let next = UnusedArguments.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // UseImplicitInit
    if context.shouldFormat(UseImplicitInit.self, node: Syntax(result)) {
        if let next = UseImplicitInit.transform(
            result, parent: parent, context: context
        ).as(FunctionDeclSyntax.self) {
            result = next
        }
    }

    // Unported rules touching FunctionDeclSyntax — tracked for sub-issue 4f:
    //   - RedundantOverride (no static transform)
    //   - RedundantEscaping (no static transform)
    //   - NoForceTry / NoForceUnwrap (file-level pre-scan, instance state)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(RedundantOverride.self, node: Syntax(result))
    _ = context.shouldFormat(RedundantEscaping.self, node: Syntax(result))
    _ = context.shouldFormat(NoForceTry.self, node: Syntax(result))
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
