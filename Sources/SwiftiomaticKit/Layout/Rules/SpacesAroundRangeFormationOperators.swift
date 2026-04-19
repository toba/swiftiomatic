import SwiftOperators
import SwiftSyntax

/// Force spaces around range operators.
package struct SpacesAroundRangeFormationOperators: LayoutRule {
    package static let key = "spacesAroundRangeFormationOperators"
    package static let description = "Force spaces around ... and ..<."
    package static let defaultValue = false
}

extension TokenStream {
    /// Returns a value indicating whether whitespace should be required around the given operator,
    /// for the given configuration.
    ///
    /// If spaces are not required (for example, range operators), then the formatter will also forbid
    /// breaks around the operator. This is to prevent situations where a break could occur before an
    /// un-spaced operator (e.g., turning `0...10` into `0<newline>...10`), which would be a breaking
    /// change because it would treat it as a prefix operator `...10` instead of an infix operator.
    func shouldRequireWhitespace(around operatorExpr: ExprSyntax) -> Bool {
        // Note that we look at the operator itself to make this determination, not the token kind.
        // The token kind (spaced or un-spaced operator) represents how the *user* wrote it, and we want
        // to ignore that and apply our own rules.
        if let binaryOperator = operatorExpr.as(BinaryOperatorExprSyntax.self) {
            let token = binaryOperator.operator
            if !config[SpacesAroundRangeFormationOperators.self],
                let binOp = operatorTable.infixOperator(named: token.text),
                let precedenceGroup = binOp.precedenceGroup,
                precedenceGroup == "RangeFormationPrecedence"
            {
                // We want to omit whitespace around range formation operators if possible. We can't do this
                // if the token is either preceded by a postfix operator, followed by a prefix operator, or
                // followed by a dot (for example, in an implicit member reference)---removing the spaces in
                // those situations would cause the parser to greedily treat the combined sequence of
                // operator characters as a single operator.
                if case .postfixOperator? = token.previousToken(viewMode: .all)?.tokenKind {
                    return true
                }

                switch token.nextToken(viewMode: .all)?.tokenKind {
                case .prefixOperator?, .period?: return true
                default: return false
                }
            }
        }

        // For all other operators, we want to require whitespace on each side. That's always safe, so
        // we don't need to be concerned about neighboring operator tokens. For example, we don't need
        // to be concerned about the user writing "4+-5" when they meant "4 + -5", because Swift would
        // always parse the former as "4 +- 5".
        return true
    }
}
