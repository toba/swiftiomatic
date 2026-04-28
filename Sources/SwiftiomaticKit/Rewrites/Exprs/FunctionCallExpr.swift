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
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = node

    applyRule(
        HoistAwait.self, to: &result,
        parent: parent, context: context,
        transform: HoistAwait.transform
    )

    applyRule(
        HoistTry.self, to: &result,
        parent: parent, context: context,
        transform: HoistTry.transform
    )

    applyRule(
        PreferAssertionFailure.self, to: &result,
        parent: parent, context: context,
        transform: PreferAssertionFailure.transform
    )

    applyRule(
        PreferDotZero.self, to: &result,
        parent: parent, context: context,
        transform: PreferDotZero.transform
    )

    applyRule(
        PreferKeyPath.self, to: &result,
        parent: parent, context: context,
        transform: PreferKeyPath.transform
    )

    applyRule(
        RedundantClosure.self, to: &result,
        parent: parent, context: context,
        transform: RedundantClosure.transform
    )

    applyRule(
        RedundantInit.self, to: &result,
        parent: parent, context: context,
        transform: RedundantInit.transform
    )

    applyRule(
        RequireFatalErrorMessage.self, to: &result,
        parent: parent, context: context,
        transform: RequireFatalErrorMessage.transform
    )

    // NoTrailingClosureParens — strips empty parens before a trailing closure
    // when the call has no arguments. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Closures/NoTrailingClosureParens.swift`.
    if context.shouldFormat(NoTrailingClosureParens.self, node: Syntax(result)) {
        result = applyNoTrailingClosureParens(result, context: context)
    }

    // PreferTrailingClosures — moves trailing closure-typed arguments out of
    // the parens. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Closures/PreferTrailingClosures.swift`.
    if context.shouldFormat(PreferTrailingClosures.self, node: Syntax(result)) {
        result = applyPreferTrailingClosures(result, context: context)
    }

    // WrapMultilineFunctionChains — when a chain spans multiple lines, place
    // every dot on its own line. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Wrap/WrapMultilineFunctionChains.swift`.
    if context.shouldFormat(WrapMultilineFunctionChains.self, node: Syntax(result)) {
        result = applyWrapMultilineFunctionChains(result, context: context)
    }

    // NestedCallLayout — reformat nested function-call chains.
    var resultExpr: ExprSyntax = ExprSyntax(result)
    if context.shouldFormat(NestedCallLayout.self, node: Syntax(result)) {
        resultExpr = NestedCallLayout.transform(result, parent: parent, context: context)
        if let typed = resultExpr.as(FunctionCallExprSyntax.self) { result = typed }
    }

    // NoForceUnwrap — chain-top wrapping when an inner force-unwrap requires
    // wrapping at this call (the chain top). Helpers in
    // `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        return noForceUnwrapRewriteFunctionCallTop(result, context: context)
    }

    return resultExpr
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

    fileprivate static let useTrailingClosure: Finding.Message = "use trailing closure syntax"
}

private let preferTrailingClosuresUseTrailing: Set<String> = [
    "async", "asyncAfter", "sync", "autoreleasepool",
]

private let preferTrailingClosuresNeverTrailing: Set<String> = [
    "performBatchUpdates",
    "expect",
]

private func applyPreferTrailingClosures(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> FunctionCallExprSyntax {
    guard node.trailingClosure == nil,
          node.leftParen != nil,
          node.rightParen != nil
    else { return node }

    let funcName = preferTrailingClosuresFunctionName(of: node.calledExpression)

    if let funcName, preferTrailingClosuresNeverTrailing.contains(funcName) { return node }
    if preferTrailingClosuresIsInConditionalContext(node) { return node }

    let args = Array(node.arguments)
    var trailingCount = 0
    for arg in args.reversed() {
        guard arg.expression.is(ClosureExprSyntax.self) else { break }
        trailingCount += 1
    }
    guard trailingCount > 0 else { return node }

    let closureArgs = Array(args.suffix(trailingCount))
    let remainingArgs = Array(args.dropLast(trailingCount))

    return trailingCount == 1
        ? preferTrailingClosuresConvertSingle(
            callNode: node,
            closureArg: closureArgs[0],
            remainingArgs: remainingArgs,
            funcName: funcName,
            context: context
        )
        : preferTrailingClosuresConvertMultiple(
            callNode: node,
            closureArgs: closureArgs,
            remainingArgs: remainingArgs,
            context: context
        )
}

private func preferTrailingClosuresConvertSingle(
    callNode: FunctionCallExprSyntax,
    closureArg: LabeledExprSyntax,
    remainingArgs: [LabeledExprSyntax],
    funcName: String?,
    context: Context
) -> FunctionCallExprSyntax {
    if closureArg.label != nil {
        guard let funcName, preferTrailingClosuresUseTrailing.contains(funcName)
        else { return callNode }
    }

    guard let closure = closureArg.expression.as(ClosureExprSyntax.self) else { return callNode }

    PreferTrailingClosures.diagnose(.useTrailingClosure, on: callNode, context: context)

    let exprTrailingTrivia = callNode.trailingTrivia
    var trailingClosure = closure.trimmed
    trailingClosure.leadingTrivia = .space
    trailingClosure.trailingTrivia = exprTrailingTrivia

    var result = callNode

    if remainingArgs.isEmpty {
        result = result
            .with(\.leftParen, nil)
            .with(\.rightParen, nil)
            .with(\.arguments, LabeledExprListSyntax([]))
    } else {
        var newArgs = remainingArgs
        newArgs[newArgs.count - 1] = newArgs[newArgs.count - 1].with(\.trailingComma, nil)
        result = result
            .with(\.arguments, LabeledExprListSyntax(newArgs))
            .with(\.rightParen, .rightParenToken())
    }

    return result.with(\.trailingClosure, trailingClosure)
}

private func preferTrailingClosuresConvertMultiple(
    callNode: FunctionCallExprSyntax,
    closureArgs: [LabeledExprSyntax],
    remainingArgs: [LabeledExprSyntax],
    context: Context
) -> FunctionCallExprSyntax {
    guard closureArgs[0].label == nil,
          closureArgs.dropFirst().allSatisfy({ $0.label != nil })
    else { return callNode }

    guard let firstClosure = closureArgs[0].expression.as(ClosureExprSyntax.self)
    else { return callNode }

    PreferTrailingClosures.diagnose(.useTrailingClosure, on: callNode, context: context)

    var trailingClosure = firstClosure.trimmed
    trailingClosure.leadingTrivia = .space

    var additionalElements: [MultipleTrailingClosureElementSyntax] = []

    for arg in closureArgs.dropFirst() {
        guard let closure = arg.expression.as(ClosureExprSyntax.self),
              let label = arg.label
        else { continue }

        additionalElements.append(
            MultipleTrailingClosureElementSyntax(
                label: .identifier(label.text, leadingTrivia: .space),
                colon: .colonToken(trailingTrivia: .space),
                closure: closure.trimmed
            )
        )
    }

    var result = callNode

    if remainingArgs.isEmpty {
        result = result
            .with(\.leftParen, nil)
            .with(\.rightParen, nil)
            .with(\.arguments, LabeledExprListSyntax([]))
    } else {
        var newArgs = remainingArgs
        newArgs[newArgs.count - 1] = newArgs[newArgs.count - 1].with(\.trailingComma, nil)
        result = result
            .with(\.arguments, LabeledExprListSyntax(newArgs))
            .with(\.rightParen, .rightParenToken())
    }

    result = result
        .with(\.trailingClosure, trailingClosure)
        .with(
            \.additionalTrailingClosures,
            MultipleTrailingClosureElementListSyntax(additionalElements)
        )
    result.trailingTrivia = callNode.trailingTrivia

    return result
}

private func preferTrailingClosuresFunctionName(of expr: ExprSyntax) -> String? {
    if let ref = expr.as(DeclReferenceExprSyntax.self) {
        ref.baseName.text
    } else if let member = expr.as(MemberAccessExprSyntax.self) {
        member.declName.baseName.text
    } else if let optional = expr.as(OptionalChainingExprSyntax.self) {
        preferTrailingClosuresFunctionName(of: optional.expression)
    } else if let force = expr.as(ForceUnwrapExprSyntax.self) {
        preferTrailingClosuresFunctionName(of: force.expression)
    } else {
        nil
    }
}

private func preferTrailingClosuresIsInConditionalContext(
    _ node: some SyntaxProtocol
) -> Bool {
    var current = Syntax(node).parent
    while let parent = current {
        if parent.is(CodeBlockSyntax.self) || parent.is(ClosureExprSyntax.self)
            || parent.is(MemberBlockSyntax.self) || parent.is(SwitchCaseSyntax.self)
        {
            return false
        }
        if parent.is(ConditionElementSyntax.self) { return true }
        if parent.is(ForStmtSyntax.self) { return true }
        if parent.is(SwitchExprSyntax.self) { return true }
        current = parent.parent
    }
    return false
}

extension Finding.Message {
    fileprivate static let wrapChain: Finding.Message =
        "wrap multiline function chain consistently"
}

private func applyWrapMultilineFunctionChains(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> FunctionCallExprSyntax {
    // Only process the outermost call in a chain.
    if wrapMultilineChainsIsInnerChainCall(ExprSyntax(node)) { return node }

    var periods = [TokenSyntax]()
    var hasFunctionCall = false
    wrapMultilineChainsCollect(
        ExprSyntax(node),
        periods: &periods,
        hasFunctionCall: &hasFunctionCall
    )
    periods.reverse()

    guard periods.count > 1, hasFunctionCall else { return node }

    let hasNewline = periods.contains { $0.leadingTrivia.containsNewlines }
    guard hasNewline else { return node }

    var periodsToWrap = Set<SyntaxIdentifier>()
    for (i, period) in periods.enumerated() {
        if period.leadingTrivia.containsNewlines { continue }
        if wrapMultilineChainsIsTypeAccess(after: period) { continue }

        if let prev = period.previousToken(viewMode: .sourceAccurate),
           wrapMultilineChainsIsClosingScope(prev)
        {
            periodsToWrap.insert(period.id)
            continue
        }

        if i + 1 < periods.count {
            let nextPeriod = periods[i + 1]
            if !nextPeriod.leadingTrivia.containsNewlines,
               !wrapMultilineChainsIsTypeAccess(after: nextPeriod)
            {
                periodsToWrap.insert(nextPeriod.id)
            }
        }
    }

    let orderedToWrap = periods.filter { periodsToWrap.contains($0.id) }
    guard !orderedToWrap.isEmpty else { return node }

    let indent: String =
        periods.first { $0.leadingTrivia.containsNewlines }?.leadingTrivia.indentation ?? "    "

    WrapMultilineFunctionChains.diagnose(.wrapChain, on: orderedToWrap[0], context: context)

    var resultExpr = ExprSyntax(node)
    for period in orderedToWrap {
        let rewriter = WrapMultilineChainsPeriodTriviaRewriter(
            targetID: period.id,
            newTrivia: .newline + Trivia(stringLiteral: indent)
        )
        resultExpr = rewriter.rewrite(Syntax(resultExpr)).cast(ExprSyntax.self)
    }
    return resultExpr.as(FunctionCallExprSyntax.self) ?? node
}

private func wrapMultilineChainsCollect(
    _ expr: ExprSyntax,
    periods: inout [TokenSyntax],
    hasFunctionCall: inout Bool
) {
    if let callExpr = expr.as(FunctionCallExprSyntax.self) {
        hasFunctionCall = true
        wrapMultilineChainsCollect(
            callExpr.calledExpression,
            periods: &periods,
            hasFunctionCall: &hasFunctionCall
        )
    } else if let subscriptExpr = expr.as(SubscriptCallExprSyntax.self) {
        hasFunctionCall = true
        wrapMultilineChainsCollect(
            subscriptExpr.calledExpression,
            periods: &periods,
            hasFunctionCall: &hasFunctionCall
        )
    } else if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
        periods.append(memberAccess.period)
        if let base = memberAccess.base {
            wrapMultilineChainsCollect(
                base,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        }
    } else if let optionalChain = expr.as(OptionalChainingExprSyntax.self) {
        wrapMultilineChainsCollect(
            optionalChain.expression,
            periods: &periods,
            hasFunctionCall: &hasFunctionCall
        )
    } else if let forceUnwrap = expr.as(ForceUnwrapExprSyntax.self) {
        wrapMultilineChainsCollect(
            forceUnwrap.expression,
            periods: &periods,
            hasFunctionCall: &hasFunctionCall
        )
    }
}

private func wrapMultilineChainsIsInnerChainCall(_ expr: ExprSyntax) -> Bool {
    guard let parent = expr.parent else { return false }
    if parent.as(MemberAccessExprSyntax.self) != nil {
        if let grandparent = parent.parent,
           grandparent.is(FunctionCallExprSyntax.self)
               || grandparent.is(SubscriptCallExprSyntax.self)
        {
            return true
        }
    }
    if parent.as(OptionalChainingExprSyntax.self) != nil
        || parent.as(ForceUnwrapExprSyntax.self) != nil
    {
        return true
    }
    return false
}

private func wrapMultilineChainsIsClosingScope(_ token: TokenSyntax) -> Bool {
    switch token.tokenKind {
        case .rightParen, .rightBrace, .rightSquare: true
        default: false
    }
}

private func wrapMultilineChainsIsTypeAccess(after period: TokenSyntax) -> Bool {
    guard let next = period.nextToken(viewMode: .sourceAccurate),
          case let .identifier(name) = next.tokenKind,
          let first = name.first, first.isUppercase
    else { return false }
    return true
}

private final class WrapMultilineChainsPeriodTriviaRewriter: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrivia: Trivia

    init(targetID: SyntaxIdentifier, newTrivia: Trivia) {
        self.targetID = targetID
        self.newTrivia = newTrivia
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if token.id == targetID { return token.with(\.leadingTrivia, newTrivia) }
        return token
    }
}
