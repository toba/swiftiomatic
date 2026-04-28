import SwiftSyntax

/// Remove parentheses around closure parameter lists when no parameter has a type annotation.
///
/// `{ (x, y) in ... }` is equivalent to `{ x, y in ... }` when the parameters are untyped — the
/// parens add visual noise. Typed parameter lists ( `{ (x: Int) in }` ) keep the parens because
/// shorthand parameters can't carry types.
///
/// Lint: A finding is raised at the parameter clause.
///
/// Rewrite: The parenthesized parameter list is converted to shorthand ( `x, y` ).
final class NoParensInClosureParams: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }

    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        guard let clause = node.parameterClause?.as(ClosureParameterClauseSyntax.self),
              !clause.parameters.isEmpty,
              clause.parameters.allSatisfy({ $0.type == nil && $0.attributes.isEmpty })
        else { return super.visit(node) }

        diagnose(.removeClosureParamParens, on: clause)

        let count = clause.parameters.count
        let shorthand = clause.parameters.enumerated().map {
            idx, param -> ClosureShorthandParameterSyntax in
            let isLast = idx == count - 1
            return ClosureShorthandParameterSyntax(
                name: param.firstName,
                trailingComma: isLast
                    ? nil
                    : .commaToken(trailingTrivia: .space)
            )
        }

        let shorthandList = ClosureShorthandParameterListSyntax(shorthand)
            .with(\.leadingTrivia, clause.leadingTrivia)
            .with(\.trailingTrivia, clause.trailingTrivia)

        var result = node
        result.parameterClause = ClosureSignatureSyntax.ParameterClause(shorthandList)
        return super.visit(result)
    }
}

fileprivate extension Finding.Message {
    static let removeClosureParamParens: Finding.Message =
        "remove parentheses around closure parameters; shorthand form is preferred"
}
