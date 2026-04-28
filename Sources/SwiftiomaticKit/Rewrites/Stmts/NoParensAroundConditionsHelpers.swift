import SwiftSyntax

/// Shared helpers for the inlined `NoParensAroundConditions` rule. The rule
/// targets multiple statement / expression nodes; each merged `rewrite<...>`
/// function calls into these helpers. See
/// `Sources/SwiftiomaticKit/Rules/Conditions/NoParensAroundConditions.swift`
/// for the legacy implementation.

/// Strip the wrapping single-element tuple from `original` if doing so would
/// not introduce a parse ambiguity. Returns the inner expression with the
/// outer parens' trivia transferred onto it, or `nil` if no stripping is
/// possible.
///
/// Emits a `removeParensAroundExpression` finding when stripping is performed.
func noParensMinimalSingleExpression(
    _ original: ExprSyntax,
    context: Context
) -> ExprSyntax? {
    guard let tuple = original.as(TupleExprSyntax.self),
          tuple.elements.count == 1,
          let expr = tuple.elements.first?.expression
    else {
        return nil
    }

    if let fnCall = expr.as(FunctionCallExprSyntax.self) {
        if fnCall.trailingClosure != nil {
            // Trailing closure — removing parens would change parsing.
            return nil
        }
        if fnCall.calledExpression.as(ClosureExprSyntax.self) != nil {
            // Immediately-called closure — same reason.
            return nil
        }
    }

    NoParensAroundConditions.diagnose(
        .removeParensAroundExpression,
        on: tuple.leftParen,
        context: context
    )

    var result = expr
    result.leadingTrivia = tuple.leftParen.leadingTrivia
    result.trailingTrivia = tuple.rightParen.trailingTrivia
    return result
}

/// Ensure the trailing trivia of a control-flow keyword has at least one
/// space after parens are removed from the following expression.
func noParensFixKeywordTrailingTrivia(_ trivia: inout Trivia) {
    guard trivia.isEmpty else { return }
    trivia = [.spaces(1)]
}

extension Finding.Message {
    fileprivate static let removeParensAroundExpression: Finding.Message =
        "remove the parentheses around this expression"
}
