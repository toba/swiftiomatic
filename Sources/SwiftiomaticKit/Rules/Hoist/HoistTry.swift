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
/// Rewrite: `try` is removed from arguments and added to wrap the call expression.
final class HoistTry: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "try" }
    override static var group: ConfigurationGroup? { .hoist }

    static func transform(
        _ callNode: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Check parent on the captured original-tree parent (post-recursion the node is detached).
        if isWrappedInTry(parent: parent) { return ExprSyntax(callNode) }

        // Find the first plain try in arguments
        guard let firstTry = findFirstTryInArguments(callNode) else { return ExprSyntax(callNode) }

        // Only hoist plain `try` (not `try?` or `try!`)
        guard firstTry.questionOrExclamationMark == nil else { return ExprSyntax(callNode) }

        Self.diagnose(.hoistTry, on: firstTry.tryKeyword, context: context)

        // Strip try from all arguments
        let newArgs = callNode.arguments.map { arg -> LabeledExprSyntax in
            arg.with(\.expression, stripTry(from: arg.expression))
        }

        let newCall = callNode.with(\.arguments, LabeledExprListSyntax(newArgs))

        // Wrap in try
        var callExpr = ExprSyntax(newCall)
        callExpr.leadingTrivia = []

        let tryExpr = TryExprSyntax(
            tryKeyword: .keyword(
                .try,
                leadingTrivia: callNode.leadingTrivia,
                trailingTrivia: .space
            ),
            expression: callExpr
        )

        var result = ExprSyntax(tryExpr)
        result.trailingTrivia = callNode.trailingTrivia
        return result
    }

    /// Compact-pipeline state: per-AwaitExpr stack of pre-recursion
    /// `(hadTryBefore, trailingTrivia)` snapshots, populated by
    /// `willEnter(_:AwaitExprSyntax, context:)` and consumed by
    /// `transform(_:AwaitExprSyntax, parent:context:)`. Reference type so it can
    /// be cached on `Context.ruleState(for:)`.
    final class AwaitState {
        var hadTryBefore: [Bool] = []
        var trailingTrivia: [Trivia] = []
        init() {}
    }

    static func willEnter(_ node: AwaitExprSyntax, context: Context) {
        let state = context.ruleState(for: HoistTry.self) { AwaitState() }
        state.hadTryBefore.append(node.expression.is(TryExprSyntax.self))
        state.trailingTrivia.append(node.trailingTrivia)
    }

    static func didExit(_ node: AwaitExprSyntax, context: Context) {
        let state = context.ruleState(for: HoistTry.self) { AwaitState() }
        if !state.hadTryBefore.isEmpty {
            state.hadTryBefore.removeLast()
        }
        if !state.trailingTrivia.isEmpty {
            state.trailingTrivia.removeLast()
        }
    }

    static func transform(
        _ node: AwaitExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        _ = parent
        let state = context.ruleState(for: HoistTry.self) { AwaitState() }
        let hadTryBefore = state.hadTryBefore.last ?? node.expression.is(TryExprSyntax.self)
        let originalTrailingTrivia = state.trailingTrivia.last ?? node.trailingTrivia
        return Self.transformAwait(
            node,
            hadTryBefore: hadTryBefore,
            originalTrailingTrivia: originalTrailingTrivia
        )
    }

    /// AwaitExpr-targeted helper. Takes `hadTryBefore` and the original trailing trivia
    /// because both rely on the pre-recursion view of the node.
    private static func transformAwait(
        _ awaitNode: AwaitExprSyntax,
        hadTryBefore: Bool,
        originalTrailingTrivia: Trivia
    ) -> ExprSyntax {
        guard
            !hadTryBefore,
            let tryExpr = awaitNode.expression.as(TryExprSyntax.self)
        else {
            return ExprSyntax(awaitNode)
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
        result.trailingTrivia = originalTrailingTrivia
        return result
    }

    /// Strips `try` from the expression, handling `await try` nesting.
    private static func stripTry(from expr: ExprSyntax) -> ExprSyntax {
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
    private static func findFirstTryInArguments(
        _ call: FunctionCallExprSyntax
    ) -> TryExprSyntax? {
        for arg in call.arguments {
            if let tryExpr = arg.expression.as(TryExprSyntax.self) { return tryExpr }

            if let awaitExpr = arg.expression.as(AwaitExprSyntax.self),
                let tryExpr = awaitExpr.expression.as(TryExprSyntax.self)
            {
                return tryExpr
            }
        }
        return nil
    }

    /// Returns `true` if the expression is wrapped in a `TryExprSyntax` ancestor. Walks the
    /// captured pre-recursion parent chain (post-recursion parent is nil).
    private static func isWrappedInTry(parent: Syntax?) -> Bool {
        var current = parent

        while let p = current {
            if p.is(TryExprSyntax.self) { return true }

            if p.is(AwaitExprSyntax.self)
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

extension Finding.Message {
    fileprivate static let hoistTry: Finding.Message = "move 'try' to the start of the expression"
}
