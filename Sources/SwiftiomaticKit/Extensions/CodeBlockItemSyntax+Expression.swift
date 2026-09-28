import SwiftSyntax

extension CodeBlockItemSyntax {
    /// The expression that this item holds, or `nil` for a declaration or another statement
    ///
    /// An `if` or a `switch` at statement position parses as an `ExpressionStmtSyntax` , so the
    /// property looks through that wrapper.
    var expression: ExprSyntax? {
        if let expression = item.as(ExprSyntax.self) { return expression }
        return item.as(ExpressionStmtSyntax.self)?.expression
    }

    /// The expression that this item holds, or the value that it returns with `return`
    var expressionOrReturnedValue: ExprSyntax? {
        if let returned = item.as(ReturnStmtSyntax.self) { return returned.expression }
        return expression
    }
}
