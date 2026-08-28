import SwiftSyntax
import SwiftOperators

/// Move inline `try` keyword(s) to the start of the expression.
///
/// When `try` appears inside function call arguments, it can be hoisted to wrap the entire call
/// expression. This is clearer and avoids redundant `try` keywords when multiple arguments throw.
///
/// For example, `foo(try bar(), try baz())` should be `try foo(bar(), baz())` .
///
/// This rule does not flag `try` inside closures (which have their own throwing context) or when
/// the call is already wrapped in `try` . Only plain `try` is hoisted (not `try?` or `try!` ).
///
/// Lint: Using `try` inside a function call argument raises a warning.
///
/// Rewrite: `try` is removed from arguments and added to wrap the call expression.
final class HoistTry: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 170

    override static var group: ConfigurationGroup? { .hoist }

    static func transform(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Check parent on the captured original-tree parent (post-recursion the node is detached).
        if isWrappedInTry(parent: parent) { return ExprSyntax(callNode) }

        // Swift rejects `try` to the right of a non-assignment operator, so leave `1 + foo(try x)`
        // alone. `original` still sits in the source tree and reports the real ancestors.
        if isRightOfNonAssignmentOperator(original, context: context) {
            return ExprSyntax(callNode)
        }

        // Find the first plain try in arguments
        guard let firstTry = findFirstTryInArguments(callNode) else { return ExprSyntax(callNode) }

        // Only hoist plain `try` (not `try?` or `try!` )
        guard firstTry.questionOrExclamationMark == nil else { return ExprSyntax(callNode) }

        // Anchor the finding on `original` , which still sits in the source file and reports the
        // real position. A `try` that `original` does not carry comes from an inner hoist in this
        // same pass, and that hoist already reported the source `try` .
        if let sourceTry = findFirstTryInArguments(original),
           sourceTry.questionOrExclamationMark == nil
        {
            Self.diagnose(.hoistTry, on: sourceTry.tryKeyword, context: context)
        }

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

    /// Moves a hoisted `try` out of a prefix operator.
    ///
    /// The call transform puts `try` at the start of the call it rewrites. When the call sits
    /// behind a prefix operator, that spot is inside the operator, and `!try foo()` does not parse.
    /// The `try` belongs in front of the operator instead: `try !foo()` .
    static func transform(
        _ node: PrefixOperatorExprSyntax,
        original _: PrefixOperatorExprSyntax,
        parent _: Syntax?,
        context _: Context
    ) -> ExprSyntax {
        guard let tryExpr = node.expression.as(TryExprSyntax.self),
            tryExpr.questionOrExclamationMark == nil else { return ExprSyntax(node) }

        var newPrefix = node.with(\.expression, tryExpr.expression)
        newPrefix.leadingTrivia = []

        let newTry = TryExprSyntax(
            tryKeyword: tryExpr.tryKeyword.with(\.leadingTrivia, node.leadingTrivia),
            expression: ExprSyntax(newPrefix)
        )
        return ExprSyntax(newTry)
    }

    /// Compact-pipeline state: per-AwaitExpr stack of pre-recursion
    /// `(hadTryBefore, trailingTrivia)` snapshots, populated by
    /// `willEnter(_:AwaitExprSyntax, context:)` and consumed by
    /// `transform(_:AwaitExprSyntax, parent:context:)` . Reference type so it can be stored as a
    /// typed lazy property on `Context` .
    final class AwaitState {
        var hadTryBefore: [Bool] = []
        var trailingTrivia: [Trivia] = []
        init() {}
    }

    static func willEnter(_ node: AwaitExprSyntax, context: Context) {
        let state = context.hoistTryState
        state.hadTryBefore.append(node.expression.is(TryExprSyntax.self))
        state.trailingTrivia.append(node.trailingTrivia)
    }

    static func didExit(_: AwaitExprSyntax, context: Context) {
        let state = context.hoistTryState
        if !state.hadTryBefore.isEmpty { state.hadTryBefore.removeLast() }
        if !state.trailingTrivia.isEmpty { state.trailingTrivia.removeLast() }
    }

    static func transform(
        _ node: AwaitExprSyntax,
        original _: AwaitExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        _ = parent
        let state = context.hoistTryState
        let hadTryBefore = state.hadTryBefore.last ?? node.expression.is(TryExprSyntax.self)
        let originalTrailingTrivia = state.trailingTrivia.last ?? node.trailingTrivia
        return Self.transformAwait(
            node,
            hadTryBefore: hadTryBefore,
            originalTrailingTrivia: originalTrailingTrivia
        )
    }

    /// AwaitExpr-targeted helper. Takes `hadTryBefore` and the original trailing trivia because
    /// both rely on the pre-recursion view of the node.
    private static func transformAwait(
        _ awaitNode: AwaitExprSyntax,
        hadTryBefore: Bool,
        originalTrailingTrivia: Trivia
    ) -> ExprSyntax {
        guard !hadTryBefore,
              let tryExpr = awaitNode.expression.as(TryExprSyntax.self)
        else { return ExprSyntax(awaitNode) }

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
                let tryExpr = awaitExpr.expression.as(TryExprSyntax.self) { return tryExpr }
        }
        return nil
    }

    /// Returns `true` when the hoisted `try` would land to the right of a non-assignment operator.
    /// Swift rejects that position with "'try' cannot appear to the right of a non-assignment
    /// operator".
    ///
    /// The walk follows the nodes the hoist cascades through, so it tracks where the `try` ends up.
    /// Once the walk leaves an operand of an infix operator, the position is fixed, and only a
    /// further infix ancestor can still invalidate it. An assignment operator accepts `try` on its
    /// right, so the walk stops there.
    private static func isRightOfNonAssignmentOperator(
        _ node: some SyntaxProtocol,
        context: Context
    ) -> Bool {
        var current = Syntax(node)
        var insideOperand = false

        while let parent = current.parent {
            if let infix = parent.as(InfixOperatorExprSyntax.self) {
                if isAssignmentOperator(infix.operator, context: context) { return false }
                if infix.leftOperand.id != current.id { return true }
                insideOperand = true
                current = parent
                continue
            }

            // The hoist moves `try` out of these nodes, so the wider expression still matters.
            if !insideOperand,
               parent.is(AwaitExprSyntax.self)
                   || parent.is(PrefixOperatorExprSyntax.self)
                   || parent.is(LabeledExprSyntax.self)
                   || parent.is(LabeledExprListSyntax.self)
                   || parent.is(FunctionCallExprSyntax.self)
            {
                current = parent
                continue
            }
            return false
        }
        return false
    }

    /// Returns `true` for `=` and for any infix operator in the `AssignmentPrecedence` group, such
    /// as `+=` .
    private static func isAssignmentOperator(_ expr: ExprSyntax, context: Context) -> Bool {
        if expr.is(AssignmentExprSyntax.self) { return true }
        guard let binary = expr.as(BinaryOperatorExprSyntax.self) else { return false }
        return context.operatorTable.infixOperator(named: binary.operator.text)?
            .precedenceGroup == "AssignmentPrecedence"
    }

    /// Returns `true` if the expression is wrapped in a `TryExprSyntax` ancestor. Walks the
    /// captured pre-recursion parent chain (post-recursion parent is nil).
    private static func isWrappedInTry(parent: Syntax?) -> Bool {
        var current = parent

        while let p = current {
            if p.is(TryExprSyntax.self) { return true }

            if p.is(AwaitExprSyntax.self)
                || p.is(PrefixOperatorExprSyntax.self)
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
    static let hoistTry: Finding.Message = "move 'try' to the start of the expression"
}
