import SwiftSyntax

/// Move inline `try` keyword(s) to the start of the expression.
///
/// When `try` appears inside function call arguments, it can be hoisted to wrap the
/// entire call expression. This is clearer and avoids redundant `try` keywords when
/// multiple arguments throw.
///
/// For example, `foo(try bar(), try baz())` should be `try foo(bar(), baz())`.
///
/// This rule does not flag `try` inside closures (which have their own throwing context)
/// or when the call is already wrapped in `try`. Only plain `try` is hoisted (not
/// `try?` or `try!`).
///
/// Lint: Using `try` inside a function call argument raises a warning.
///
/// Format: `try` is removed from arguments and added to wrap the call expression.
final class HoistTry: RewriteSyntaxRule<BasicRuleValue> {
    override class var key: String { "tryWithinExpression" }
    override class var group: ConfigurationGroup? { .hoist }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check parent on original node before visiting children
        if isWrappedInTry(ExprSyntax(node)) {
            return super.visit(node)
        }

        let visited = super.visit(node)
        guard let callNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

        // Find the first plain try in arguments
        guard let firstTry = findFirstTryInArguments(callNode) else { return visited }

        // Only hoist plain `try` (not `try?` or `try!`)
        guard firstTry.questionOrExclamationMark == nil else { return visited }

        diagnose(.hoistTry, on: firstTry.tryKeyword)

        // Strip try from all arguments
        let newArgs = callNode.arguments.map { arg -> LabeledExprSyntax in
            arg.with(\.expression, stripTry(from: arg.expression))
        }

        let newCall = callNode.with(\.arguments, LabeledExprListSyntax(newArgs))

        // Wrap in try
        var callExpr = ExprSyntax(newCall)
        callExpr.leadingTrivia = []

        let tryExpr = TryExprSyntax(
            tryKeyword: .keyword(.try, leadingTrivia: node.leadingTrivia, trailingTrivia: .space),
            expression: callExpr
        )

        var result = ExprSyntax(tryExpr)
        result.trailingTrivia = node.trailingTrivia
        return result
    }

    /// Reorders `await try X` → `try await X` when `try` was introduced by hoisting
    /// (not already present in the source).
    override func visit(_ node: AwaitExprSyntax) -> ExprSyntax {
        let hadTryBefore = node.expression.is(TryExprSyntax.self)
        let visited = super.visit(node)
        guard let awaitNode = visited.as(AwaitExprSyntax.self),
            !hadTryBefore,
            let tryExpr = awaitNode.expression.as(TryExprSyntax.self)
        else {
            return visited
        }

        // Move try outside await
        var newAwait = awaitNode.with(\.expression, tryExpr.expression)
        newAwait.awaitKeyword = newAwait.awaitKeyword.with(\.leadingTrivia, [])

        let newTry = TryExprSyntax(
            tryKeyword: tryExpr.tryKeyword
                .with(\.leadingTrivia, awaitNode.awaitKeyword.leadingTrivia),
            expression: ExprSyntax(newAwait)
        )
        var result = ExprSyntax(newTry)
        result.trailingTrivia = node.trailingTrivia
        return result
    }

    /// Strips `try` from the expression, handling `await try` nesting.
    private func stripTry(from expr: ExprSyntax) -> ExprSyntax {
        if let tryExpr = expr.as(TryExprSyntax.self),
            tryExpr.questionOrExclamationMark == nil
        {
            var inner = tryExpr.expression
            inner.leadingTrivia = expr.leadingTrivia
            return inner
        }
        if let awaitExpr = expr.as(AwaitExprSyntax.self),
            let tryExpr = awaitExpr.expression.as(TryExprSyntax.self),
            tryExpr.questionOrExclamationMark == nil
        {
            var inner = tryExpr.expression
            inner.leadingTrivia = tryExpr.leadingTrivia
            return ExprSyntax(awaitExpr.with(\.expression, inner))
        }
        return expr
    }

    /// Returns the first `TryExprSyntax` found as a direct argument expression.
    private func findFirstTryInArguments(_ call: FunctionCallExprSyntax) -> TryExprSyntax? {
        for arg in call.arguments {
            if let tryExpr = arg.expression.as(TryExprSyntax.self) {
                return tryExpr
            }
            if let awaitExpr = arg.expression.as(AwaitExprSyntax.self),
                let tryExpr = awaitExpr.expression.as(TryExprSyntax.self)
            {
                return tryExpr
            }
        }
        return nil
    }

    /// Returns `true` if the expression is wrapped in a `TryExprSyntax` ancestor.
    private func isWrappedInTry(_ expr: ExprSyntax) -> Bool {
        var current: Syntax = Syntax(expr)
        while let parent = current.parent {
            if parent.is(TryExprSyntax.self) {
                return true
            }
            if parent.is(AwaitExprSyntax.self)
                || parent.is(LabeledExprSyntax.self)
                || parent.is(LabeledExprListSyntax.self)
                || parent.is(FunctionCallExprSyntax.self)
            {
                current = parent
                continue
            }
            break
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let hoistTry: Finding.Message =
        "move 'try' to the start of the expression"
}
