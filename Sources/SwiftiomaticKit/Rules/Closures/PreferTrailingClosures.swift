import SwiftSyntax

/// Use trailing closure syntax where applicable.
///
/// When the last argument(s) to a function call are closure expressions, convert
/// them to trailing closure syntax. For a single trailing closure, the closure must
/// be unlabeled unless the function is in the "always trailing" list (e.g. `async`,
/// `sync`, `autoreleasepool`). For multiple trailing closures, the first must be
/// unlabeled and the rest must be labeled.
///
/// Lint: When closure arguments could use trailing closure syntax.
///
/// Format: The closure arguments are moved to trailing closure position.
final class PreferTrailingClosures: RewriteSyntaxRule<BasicRuleValue> {
    override static var group: ConfigurationGroup? { .closures }

    /// Function names where labeled closures should still be made trailing.
    private static let useTrailing: Set<String> = [
        "async", "asyncAfter", "sync", "autoreleasepool",
    ]

    /// Function names that should never use trailing closures.
    private static let neverTrailing: Set<String> = [
        "performBatchUpdates",
        "expect",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let callNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

        // Already has a trailing closure
        guard callNode.trailingClosure == nil else { return visited }

        // Must have parens (not already trailing-closure style)
        guard callNode.leftParen != nil, callNode.rightParen != nil else { return visited }

        let funcName = Self.functionName(of: callNode.calledExpression)

        if let funcName, Self.neverTrailing.contains(funcName) { return visited }

        // Don't convert in conditional contexts where trailing closure is ambiguous
        if isInConditionalContext(node) { return visited }

        // Find suffix of arguments that are all closures
        let args = Array(callNode.arguments)
        var trailingCount = 0

        for arg in args.reversed() {
            guard arg.expression.is(ClosureExprSyntax.self) else { break }
            trailingCount += 1
        }
        guard trailingCount > 0 else { return visited }

        let closureArgs = Array(args.suffix(trailingCount))
        let remainingArgs = Array(args.dropLast(trailingCount))

        if trailingCount == 1 {
            return convertSingle(
                callNode: callNode,
                closureArg: closureArgs[0],
                remainingArgs: remainingArgs,
                funcName: funcName,
                originalNode: node
            )
        } else {
            return convertMultiple(
                callNode: callNode,
                closureArgs: closureArgs,
                remainingArgs: remainingArgs,
                originalNode: node
            )
        }
    }

    // MARK: - Single Trailing Closure

    private func convertSingle(
        callNode: FunctionCallExprSyntax,
        closureArg: LabeledExprSyntax,
        remainingArgs: [LabeledExprSyntax],
        funcName: String?,
        originalNode: FunctionCallExprSyntax
    ) -> ExprSyntax {
        if closureArg.label != nil {
            guard let funcName, Self.useTrailing.contains(funcName) else {
                return ExprSyntax(callNode)
            }
        }

        guard let closure = closureArg.expression.as(ClosureExprSyntax.self) else {
            return ExprSyntax(callNode)
        }

        diagnose(.useTrailingClosure, on: originalNode)

        let exprTrailingTrivia = callNode.trailingTrivia
        var trailingClosure = closure.trimmed
        trailingClosure.leadingTrivia = .space
        trailingClosure.trailingTrivia = exprTrailingTrivia

        var result = callNode

        if remainingArgs.isEmpty {
            result =
                result
                .with(\.leftParen, nil)
                .with(\.rightParen, nil)
                .with(\.arguments, LabeledExprListSyntax([]))
        } else {
            var newArgs = remainingArgs
            newArgs[newArgs.count - 1] = newArgs[newArgs.count - 1]
                .with(\.trailingComma, nil)
            result =
                result
                .with(\.arguments, LabeledExprListSyntax(newArgs))
                .with(\.rightParen, .rightParenToken())
        }

        return .init(result.with(\.trailingClosure, trailingClosure))
    }

    // MARK: - Multiple Trailing Closures

    private func convertMultiple(
        callNode: FunctionCallExprSyntax,
        closureArgs: [LabeledExprSyntax],
        remainingArgs: [LabeledExprSyntax],
        originalNode: FunctionCallExprSyntax
    ) -> ExprSyntax {
        // First must be unlabeled, rest must be labeled
        guard closureArgs[0].label == nil,
            closureArgs.dropFirst().allSatisfy({ $0.label != nil })
        else { return ExprSyntax(callNode) }

        guard let firstClosure = closureArgs[0].expression.as(ClosureExprSyntax.self) else {
            return ExprSyntax(callNode)
        }

        diagnose(.useTrailingClosure, on: originalNode)

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
            result =
                result
                .with(\.leftParen, nil)
                .with(\.rightParen, nil)
                .with(\.arguments, LabeledExprListSyntax([]))
        } else {
            var newArgs = remainingArgs
            newArgs[newArgs.count - 1] = newArgs[newArgs.count - 1]
                .with(\.trailingComma, nil)
            result =
                result
                .with(\.arguments, LabeledExprListSyntax(newArgs))
                .with(\.rightParen, .rightParenToken())
        }

        result =
            result
            .with(\.trailingClosure, trailingClosure)
            .with(
                \.additionalTrailingClosures,
                MultipleTrailingClosureElementListSyntax(additionalElements)
            )
        result.trailingTrivia = callNode.trailingTrivia

        return .init(result)
    }

    // MARK: - Helpers

    private static func functionName(of expr: ExprSyntax) -> String? {
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text }
        if let member = expr.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }
        if let optional = expr.as(OptionalChainingExprSyntax.self) {
            return functionName(of: optional.expression)
        }
        if let force = expr.as(ForceUnwrapExprSyntax.self) {
            return functionName(of: force.expression)
        }
        return nil
    }

    /// Whether the call is in a context where trailing closure syntax would
    /// be ambiguous (condition expressions, for-in sequences, switch subjects).
    private func isInConditionalContext(_ node: some SyntaxProtocol) -> Bool {
        var current = Syntax(node).parent

        while let parent = current {
            // Scope boundaries — inside a body, not a condition
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

extension Finding.Message {
    fileprivate static let useTrailingClosure: Finding.Message = "use trailing closure syntax"
}
