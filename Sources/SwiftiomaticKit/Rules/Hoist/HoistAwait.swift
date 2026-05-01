import SwiftSyntax

/// Move inline `await` keyword(s) to the start of the expression.
///
/// When `await` appears inside function call arguments, it can be hoisted to wrap the entire call
/// expression. This is clearer and avoids redundant `await` keywords when multiple arguments are
/// async.
///
/// For example, `foo(await bar(), await baz())` should be `await foo(bar(), baz())` .
///
/// This rule does not flag `await` inside closures (which have their own async context) or when the
/// call is already wrapped in `await` .
///
/// Lint: Using `await` inside a function call argument raises a warning.
///
/// Rewrite: `await` is removed from arguments and added to wrap the call expression.
final class HoistAwait: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var key: String { "await" }
    override class var group: ConfigurationGroup? { .hoist }

    static func transform(
        _ callNode: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Check parent on the captured original-tree parent (post-recursion the node is detached).
        if isWrappedInAwait(parent: parent) { return ExprSyntax(callNode) }

        // Find the first await in arguments
        guard let firstAwait = findFirstAwaitInArguments(callNode) else {
            return ExprSyntax(callNode)
        }

        Self.diagnose(.hoistAwait, on: firstAwait.awaitKeyword, context: context)

        // Strip await from all arguments
        let newArgs = callNode.arguments.map { arg -> LabeledExprSyntax in
            arg.with(\.expression, stripAwait(from: arg.expression))
        }

        let newCall = callNode.with(\.arguments, LabeledExprListSyntax(newArgs))

        // Wrap in await
        var callExpr = ExprSyntax(newCall)
        callExpr.leadingTrivia = []

        let awaitExpr = AwaitExprSyntax(
            awaitKeyword: .keyword(
                .await,
                leadingTrivia: callNode.leadingTrivia,
                trailingTrivia: .space
            ),
            expression: callExpr
        )

        var result = ExprSyntax(awaitExpr)
        result.trailingTrivia = callNode.trailingTrivia
        return result
    }

    /// Strips `await` from the expression, handling `try await` nesting.
    private static func stripAwait(from expr: ExprSyntax) -> ExprSyntax {
        if let awaitExpr = expr.as(AwaitExprSyntax.self) {
            var inner = awaitExpr.expression
            inner.leadingTrivia = expr.leadingTrivia
            return inner
        }
        if let tryExpr = expr.as(TryExprSyntax.self),
           let awaitExpr = tryExpr.expression.as(AwaitExprSyntax.self)
        {
            var inner = awaitExpr.expression
            inner.leadingTrivia = awaitExpr.leadingTrivia
            return ExprSyntax(tryExpr.with(\.expression, inner))
        }
        return expr
    }

    /// Returns the first `AwaitExprSyntax` found as a direct argument expression.
    private static func findFirstAwaitInArguments(
        _ call: FunctionCallExprSyntax
    ) -> AwaitExprSyntax? {
        for arg in call.arguments {
            if let awaitExpr = arg.expression.as(AwaitExprSyntax.self) { return awaitExpr }
            if let tryExpr = arg.expression.as(TryExprSyntax.self),
               let awaitExpr = tryExpr.expression.as(AwaitExprSyntax.self)
            {
                return awaitExpr
            }
        }
        return nil
    }

    /// Returns `true` if the expression is wrapped in an `AwaitExprSyntax` ancestor. Walks the
    /// captured pre-recursion parent chain (post-recursion parent is nil).
    private static func isWrappedInAwait(parent: Syntax?) -> Bool {
        var current = parent

        while let p = current {
            if p.is(AwaitExprSyntax.self) { return true }

            if p.is(TryExprSyntax.self)
                || p.is(LabeledExprSyntax.self)
                || p.is(LabeledExprListSyntax.self)
                || p.is(FunctionCallExprSyntax.self)
            {
                current = p.parent
                continue
            }
            break
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let hoistAwait: Finding.Message = "move 'await' to the start of the expression"
}
