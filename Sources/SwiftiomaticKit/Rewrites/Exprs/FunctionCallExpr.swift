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

    // NoTrailingClosureParens — strips empty parens before a trailing closure
    // when the call has no arguments. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Closures/NoTrailingClosureParens.swift`.
    if context.shouldFormat(NoTrailingClosureParens.self, node: Syntax(result)) {
        result = applyNoTrailingClosureParens(result, context: context)
    }

    // Unported rules — tracked for sub-issue 4f. Audit-only:
    //   - NoForceUnwrap (file-level pre-scan, instance state)
    //   - PreferTrailingClosures (no static transform)
    //   - NestedCallLayout (no static transform)
    //   - WrapMultilineFunctionChains (no static transform)
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))
    _ = context.shouldFormat(PreferTrailingClosures.self, node: Syntax(result))
    _ = context.shouldFormat(NestedCallLayout.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineFunctionChains.self, node: Syntax(result))

    return result
}

private func applyNoTrailingClosureParens(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> FunctionCallExprSyntax {
    guard node.arguments.isEmpty,
          let trailingClosure = node.trailingClosure,
          let leftParen = node.leftParen,
          let rightParen = node.rightParen,
          !leftParen.trailingTrivia.hasAnyComments,
          !rightParen.leadingTrivia.hasAnyComments,
          let name = node.calledExpression.lastToken(viewMode: .sourceAccurate),
          // Keep parens in curried calls so the trailing closure doesn't
          // associate with the inner call.
          !node.calledExpression.is(FunctionCallExprSyntax.self),
          !node.calledExpression.is(SubscriptCallExprSyntax.self)
    else {
        return node
    }
    _ = trailingClosure  // referenced for the early-out guard

    NoTrailingClosureParens.diagnose(
        .removeEmptyTrailingParentheses(name: "\(name.trimmedDescription)"),
        on: leftParen,
        context: context
    )

    var rewrittenCalledExpr = node.calledExpression
    rewrittenCalledExpr.trailingTrivia = [.spaces(1)]

    var result = node
    result.leftParen = nil
    result.rightParen = nil
    result.calledExpression = rewrittenCalledExpr
    return result
}

extension Finding.Message {
    fileprivate static func removeEmptyTrailingParentheses(name: String) -> Finding.Message {
        "remove the empty parentheses following '\(name)'"
    }
}
