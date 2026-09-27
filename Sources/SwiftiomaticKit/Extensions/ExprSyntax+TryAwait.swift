import SwiftSyntax

extension ExprSyntax {
    /// The expression without any `try` or `await` layers around it.
    ///
    /// `try await f()` and `await try f()` both give `f()` . A `try?` or `try!` layer is removed
    /// too, so a caller that treats those forms differently checks for them first.
    var unwrappingTryAwait: ExprSyntax {
        if let tryExpr = self.as(TryExprSyntax.self) {
            return tryExpr.expression.unwrappingTryAwait
        }
        if let awaitExpr = self.as(AwaitExprSyntax.self) {
            return awaitExpr.expression.unwrappingTryAwait
        }
        return self
    }
}
