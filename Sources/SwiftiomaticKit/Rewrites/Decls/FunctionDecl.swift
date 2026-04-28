import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `FunctionDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteFunctionDecl(
    _ node: FunctionDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeclSyntax {
    var result = node

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        ModifierOrder.self, to: &result,
        parent: parent, context: context,
        transform: ModifierOrder.transform
    )

    applyRule(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, context: context,
        transform: ModifiersOnSameLine.transform
    )

    applyRule(
        NoExplicitOwnership.self, to: &result,
        parent: parent, context: context,
        transform: NoExplicitOwnership.transform
    )

    applyRule(
        NoGuardInTests.self, to: &result,
        parent: parent, context: context,
        transform: NoGuardInTests.transform
    )

    applyRule(
        OpaqueGenericParameters.self, to: &result,
        parent: parent, context: context,
        transform: OpaqueGenericParameters.transform
    )

    applyRule(
        RedundantAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAccessControl.transform
    )

    applyRule(
        RedundantAsync.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAsync.transform
    )

    applyRule(
        RedundantObjc.self, to: &result,
        parent: parent, context: context,
        transform: RedundantObjc.transform
    )

    applyRule(
        RedundantReturn.self, to: &result,
        parent: parent, context: context,
        transform: RedundantReturn.transform
    )

    applyRule(
        RedundantThrows.self, to: &result,
        parent: parent, context: context,
        transform: RedundantThrows.transform
    )

    applyRule(
        RedundantViewBuilder.self, to: &result,
        parent: parent, context: context,
        transform: RedundantViewBuilder.transform
    )

    applyRule(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, context: context,
        transform: SimplifyGenericConstraints.transform
    )

    applyRule(
        SwiftTestingTestCaseNames.self, to: &result,
        parent: parent, context: context,
        transform: SwiftTestingTestCaseNames.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    applyRule(
        UnusedArguments.self, to: &result,
        parent: parent, context: context,
        transform: UnusedArguments.transform
    )

    applyRule(
        UseImplicitInit.self, to: &result,
        parent: parent, context: context,
        transform: UseImplicitInit.transform
    )

    // NoForceTry — after children visit, add a `throws` clause if any inner
    // `try!` was converted. Scope state pushed/popped by the
    // generator-emitted `willEnter`/`didExit` hooks; this site only finalises
    // the function. Helpers in `Rewrites/Exprs/NoForceTryHelpers.swift`.
    if context.shouldFormat(NoForceTry.self, node: Syntax(result)) {
        result = noForceTryAfterFunctionDecl(result, context: context)
    }

    // NoForceUnwrap — after children visit, add a `throws` clause if any
    // inner force unwrap was wrapped. Scope state pushed/popped by the
    // generator-emitted `willEnter`/`didExit` hooks; this site only finalises
    // the function. Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        result = noForceUnwrapAfterFunctionDecl(result, context: context)
    }

    // RedundantEscaping — strip redundant `@escaping` from non-escaping
    // closure parameters.
    applyRule(
        RedundantEscaping.self, to: &result,
        parent: parent, context: context,
        transform: RedundantEscaping.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // RedundantOverride — delete `override` declarations that only forward to
    // `super` with identical args. Returns an empty DeclSyntax (just trivia)
    // when removal applies; that propagates through the override's DeclSyntax
    // return and is handled by the parent member-block / code-block list as a
    // missing decl.
    if context.shouldFormat(RedundantOverride.self, node: Syntax(result)) {
        return RedundantOverride.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}
