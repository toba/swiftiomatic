import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `FunctionDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteFunctionDecl(
    _ node: FunctionDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        ModifierOrder.self, to: &result,
        parent: parent, transform: ModifierOrder.transform
    )

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        NoExplicitOwnership.self, to: &result,
        parent: parent, transform: NoExplicitOwnership.transform
    )

    context.applyRewrite(
        NoGuardInTests.self, to: &result,
        parent: parent, transform: NoGuardInTests.transform
    )

    context.applyRewrite(
        OpaqueGenericParameters.self, to: &result,
        parent: parent, transform: OpaqueGenericParameters.transform
    )

    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        RedundantAsync.self, to: &result,
        parent: parent, transform: RedundantAsync.transform
    )

    context.applyRewrite(
        RedundantObjc.self, to: &result,
        parent: parent, transform: RedundantObjc.transform
    )

    context.applyRewrite(
        RedundantReturn.self, to: &result,
        parent: parent, transform: RedundantReturn.transform
    )

    context.applyRewrite(
        RedundantThrows.self, to: &result,
        parent: parent, transform: RedundantThrows.transform
    )

    context.applyRewrite(
        RedundantViewBuilder.self, to: &result,
        parent: parent, transform: RedundantViewBuilder.transform
    )

    context.applyRewrite(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, transform: SimplifyGenericConstraints.transform
    )

    context.applyRewrite(
        SwiftTestingTestCaseNames.self, to: &result,
        parent: parent, transform: SwiftTestingTestCaseNames.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    context.applyRewrite(
        UnusedArguments.self, to: &result,
        parent: parent, transform: UnusedArguments.transform
    )

    context.applyRewrite(
        UseImplicitInit.self, to: &result,
        parent: parent, transform: UseImplicitInit.transform
    )

    // NoForceTry — after children visit, add a `throws` clause if any inner
    // `try!` was converted. Scope state pushed/popped by `willEnter`/`didExit`
    // hooks on the rule; this site only finalises the function.
    if context.shouldRewrite(NoForceTry.self, at: Syntax(result)) {
        result = NoForceTry.afterFunctionDecl(result, context: context)
    }

    // NoForceUnwrap — after children visit, add a `throws` clause if any
    // inner force unwrap was wrapped. Scope state pushed/popped by the
    // generator-emitted `willEnter`/`didExit` hooks; this site only finalises
    // the function. Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)) {
        result = NoForceUnwrap.afterFunctionDecl(result, context: context)
    }

    // RedundantEscaping — strip redundant `@escaping` from non-escaping
    // closure parameters.
    context.applyRewrite(
        RedundantEscaping.self, to: &result,
        parent: parent, transform: RedundantEscaping.transform
    )

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // WrapSingleLineBodies — wrap or inline single-statement function body.
    context.applyRewrite(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, transform: WrapSingleLineBodies.transform
    )

    // PreferSwiftTesting — convert XCTestCase setUp/tearDown/test methods to
    // Swift Testing equivalents. May widen `FunctionDecl` to
    // `InitializerDecl`/`DeinitializerDecl`. Direct dispatch with early
    // return when the kind changes.
    if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(result)) {
        let widened = PreferSwiftTesting.transform(result, parent: parent, context: context)
        if let stillFunc = widened.as(FunctionDeclSyntax.self) {
            result = stillFunc
        } else {
            return widened
        }
    }

    // RedundantOverride — delete `override` declarations that only forward to
    // `super` with identical args. Returns an empty DeclSyntax (just trivia)
    // when removal applies; that propagates through the override's DeclSyntax
    // return and is handled by the parent member-block / code-block list as a
    // missing decl.
    if context.shouldRewrite(RedundantOverride.self, at: Syntax(result)) {
        return RedundantOverride.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}
