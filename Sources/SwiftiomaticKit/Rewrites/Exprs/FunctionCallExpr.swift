import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `FunctionCallExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteFunctionCallExpr(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> FunctionCallExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // HoistAwait
    if context.shouldFormat(HoistAwait.self, node: Syntax(result)) {
        if let next = HoistAwait.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // HoistTry
    if context.shouldFormat(HoistTry.self, node: Syntax(result)) {
        if let next = HoistTry.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // PreferAssertionFailure
    if context.shouldFormat(PreferAssertionFailure.self, node: Syntax(result)) {
        if let next = PreferAssertionFailure.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // PreferDotZero
    if context.shouldFormat(PreferDotZero.self, node: Syntax(result)) {
        if let next = PreferDotZero.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // PreferKeyPath
    if context.shouldFormat(PreferKeyPath.self, node: Syntax(result)) {
        if let next = PreferKeyPath.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // RedundantClosure
    if context.shouldFormat(RedundantClosure.self, node: Syntax(result)) {
        if let next = RedundantClosure.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // RedundantInit
    if context.shouldFormat(RedundantInit.self, node: Syntax(result)) {
        if let next = RedundantInit.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // RequireFatalErrorMessage
    if context.shouldFormat(RequireFatalErrorMessage.self, node: Syntax(result)) {
        if let next = RequireFatalErrorMessage.transform(
            result, parent: parent, context: context
        ).as(FunctionCallExprSyntax.self) {
            result = next
        }
    }

    // Unported rules touching FunctionCallExprSyntax — tracked for sub-issue
    // 4f. Audit-only `shouldFormat` calls preserve rule-mask gating:
    //   - NoForceUnwrap (file-level pre-scan, instance state)
    //   - NoTrailingClosureParens (no static transform)
    //   - PreferTrailingClosures (no static transform)
    //   - NestedCallLayout (no static transform)
    //   - WrapMultilineFunctionChains (no static transform)
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))
    _ = context.shouldFormat(NoTrailingClosureParens.self, node: Syntax(result))
    _ = context.shouldFormat(PreferTrailingClosures.self, node: Syntax(result))
    _ = context.shouldFormat(NestedCallLayout.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineFunctionChains.self, node: Syntax(result))

    return result
}
