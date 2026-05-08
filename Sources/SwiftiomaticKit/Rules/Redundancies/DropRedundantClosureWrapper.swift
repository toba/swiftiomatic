import SwiftSyntax

/// Remove immediately-invoked closures containing a single expression.
///
/// A closure that is immediately called and contains only a single expression or return statement
/// can be replaced with just the expression.
///
/// For example: `let x = { return 42 }()` → `let x = 42` And: `let x = { someValue }()` →
/// `let x = someValue`
///
/// Closures with parameters ( `in` keyword), multiple statements, empty bodies, `fatalError` /
/// `preconditionFailure` calls, or `throw` are preserved.
///
/// Lint: If a redundant immediately-invoked closure is found, a lint warning is raised.
///
/// Rewrite: The closure wrapper and invocation are removed, leaving just the expression.
final class DropRedundantClosureWrapper: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ callNode: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Must be a closure called with no arguments: `{ ... }()`
        guard let closureExpr = callNode.calledExpression.as(ClosureExprSyntax.self),
              callNode.arguments.isEmpty,
              callNode.additionalTrailingClosures.isEmpty,
              closureExpr.signature == nil else { return ExprSyntax(callNode) }

        // Must have exactly one statement
        guard let onlyItem = closureExpr.statements.firstAndOnly else {
            return ExprSyntax(callNode)
        }

        // Extract the single expression (strip `return` if present)
        let innerExpr: ExprSyntax

        if let returnStmt = onlyItem.item.as(ReturnStmtSyntax.self),
           let returnExpr = returnStmt.expression
        {
            innerExpr = returnExpr
        } else if let exprStmt = onlyItem.item.as(ExpressionStmtSyntax.self) {
            innerExpr = exprStmt.expression
        } else if let expr = onlyItem.item.as(ExprSyntax.self) {
            innerExpr = expr
        } else {
            return ExprSyntax(callNode)
        }

        // Skip closures that call fatalError/preconditionFailure or throw
        if containsNeverOrThrow(innerExpr) { return ExprSyntax(callNode) }

        // Skip closures wrapped in try/await (complex interaction). Use captured pre-recursion
        // parent.
        if parent?.as(TryExprSyntax.self) != nil
            || parent?.as(AwaitExprSyntax.self) != nil
        {
            return ExprSyntax(callNode)
        }

        // `switch`/`if`/`do` are expressions only in return, throw, or assignment-RHS positions.
        // Removing the IIFE in argument/subscript/etc. positions would produce uncompilable code.
        if isControlFlowExpression(innerExpr),
           !isAssignmentLikePosition(parent)
        {
            return ExprSyntax(callNode)
        }

        Self.diagnose(.removeRedundantClosure, on: closureExpr.leftBrace, context: context)

        // Replace { expr }() with expr, transferring boundary trivia
        var result = innerExpr.trimmed
        result.leadingTrivia = callNode.leadingTrivia
        result.trailingTrivia = callNode.trailingTrivia
        return result
    }

    // MARK: - Helpers

    private static func isControlFlowExpression(_ expr: ExprSyntax) -> Bool {
        expr.is(SwitchExprSyntax.self) || expr.is(IfExprSyntax.self)
    }

    private static func isAssignmentLikePosition(_ parent: Syntax?) -> Bool {
        guard let parent else { return false }
        if parent.is(InitializerClauseSyntax.self) { return true }
        if parent.is(ReturnStmtSyntax.self) { return true }
        if parent.is(ThrowStmtSyntax.self) { return true }
        if let infix = parent.as(InfixOperatorExprSyntax.self),
           infix.operator.is(AssignmentExprSyntax.self)
        {
            return true
        }
        return false
    }

    private static func containsNeverOrThrow(_ expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self),
           let ref = call.calledExpression.as(DeclReferenceExprSyntax.self)
        {
            let name = ref.baseName.text
            if name == "fatalError" || name == "preconditionFailure" { return true }
        }

        for child in expr.children(viewMode: .sourceAccurate) {
            if child.is(ThrowStmtSyntax.self) { return true }
            if let childExpr = child.as(ExprSyntax.self),
               containsNeverOrThrow(childExpr)
            {
                return true
            }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantClosure: Finding.Message =
        "remove immediately-invoked closure; use the expression directly"
}
