import SwiftSyntax

/// Use trailing closure syntax where applicable.
///
/// When the last argument(s) to a function call are closure expressions, convert them to trailing
/// closure syntax. For a single trailing closure, the closure must be unlabeled unless the function
/// is in the "always trailing" list (e.g. `async` , `sync` , `autoreleasepool` ). For multiple
/// trailing closures, the first must be unlabeled and the rest must be labeled.
///
/// Lint: When closure arguments could use trailing closure syntax.
///
/// Rewrite: The closure arguments are moved to trailing closure position.
final class UseTrailingClosures: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .closures }

    /// Functions whose labelled trailing-closure argument is still safe to convert to a trailing
    /// closure.
    private static let useTrailing: Set<String> = [
        "async", "asyncAfter", "sync", "autoreleasepool",
    ]

    /// Functions that should never use trailing-closure syntax.
    private static let neverTrailing: Set<String> = [
        "performBatchUpdates",
        "expect",
    ]

    /// Move trailing closure-typed arguments out of the parens. Called from
    /// `CompactSyntaxRewriter.visit(_: FunctionCallExprSyntax)` .
    ///
    /// `parent` must be the *original* parent of the node, captured before `super.visit` runs.
    /// `node.parent` is nil here because rewritten children produce a detached node, so we cannot
    /// walk upward from the node itself.
    static func apply(
        _ node: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> FunctionCallExprSyntax {
        guard node.trailingClosure == nil,
              node.leftParen != nil,
              node.rightParen != nil else { return node }

        let funcName = functionName(of: node.calledExpression)

        if let funcName, neverTrailing.contains(funcName) { return node }
        if isInConditionalContext(parent: parent) { return node }

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
            ? convertSingle(
                callNode: node,
                closureArg: closureArgs[0],
                remainingArgs: remainingArgs,
                funcName: funcName,
                context: context
            )
            : convertMultiple(
                callNode: node,
                closureArgs: closureArgs,
                remainingArgs: remainingArgs,
                context: context
            )
    }

    private static func convertSingle(
        callNode: FunctionCallExprSyntax,
        closureArg: LabeledExprSyntax,
        remainingArgs: [LabeledExprSyntax],
        funcName: String?,
        context: Context
    ) -> FunctionCallExprSyntax {
        if closureArg.label != nil {
            guard let funcName, useTrailing.contains(funcName) else { return callNode }
        }

        guard let closure = closureArg.expression.as(ClosureExprSyntax.self) else {
            return callNode
        }

        Self.diagnose(.useTrailingClosure, on: callNode, context: context)

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

    private static func convertMultiple(
        callNode: FunctionCallExprSyntax,
        closureArgs: [LabeledExprSyntax],
        remainingArgs: [LabeledExprSyntax],
        context: Context
    ) -> FunctionCallExprSyntax {
        guard closureArgs[0].label == nil,
              closureArgs.dropFirst().allSatisfy({ $0.label != nil }) else { return callNode }

        guard let firstClosure = closureArgs[0].expression.as(ClosureExprSyntax.self) else {
            return callNode
        }

        Self.diagnose(.useTrailingClosure, on: callNode, context: context)

        var trailingClosure = firstClosure.trimmed
        trailingClosure.leadingTrivia = .space

        var additionalElements: [MultipleTrailingClosureElementSyntax] = []

        for arg in closureArgs.dropFirst() {
            guard let closure = arg.expression.as(ClosureExprSyntax.self),
                  let label = arg.label else { continue }

            additionalElements.append(
                MultipleTrailingClosureElementSyntax(
                    label: .identifier(label.text, leadingTrivia: .space),
                    colon: .colonToken(trailingTrivia: .space),
                    closure: closure.trimmed
                ))
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

    private static func functionName(of expr: ExprSyntax) -> String? {
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            ref.baseName.text
        } else if let member = expr.as(MemberAccessExprSyntax.self) {
            member.declName.baseName.text
        } else if let optional = expr.as(OptionalChainingExprSyntax.self) {
            functionName(of: optional.expression)
        } else if let force = expr.as(ForceUnwrapExprSyntax.self) {
            functionName(of: force.expression)
        } else {
            nil
        }
    }

    private static func isInConditionalContext(parent: Syntax?) -> Bool {
        var current = parent

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
}

fileprivate extension Finding.Message {
    static let useTrailingClosure: Finding.Message = "use trailing closure syntax"
}
