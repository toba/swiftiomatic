import SwiftSyntax

/// Prefer `count(where:)` over `filter(_:).count` .
///
/// The `count(where:)` method (Swift 6.0+) is more expressive and avoids allocating an intermediate
/// array just to count its elements.
///
/// Lint: Using `.filter { ... }.count` raises a warning suggesting `count(where:)` .
///
/// Rewrite: `.filter { ... }.count` is replaced with `.count(where: { ... })` .
final class PreferCountWhere: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .collections }

    static func transform(
        _ memberNode: MemberAccessExprSyntax,
        original _: MemberAccessExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // If .count is a method call (parent is FunctionCallExprSyntax with this as
        // calledExpression), skip — uses the captured pre-recursion parent since the post-visit
        // node is detached.
        if let parentCall = parent?.as(FunctionCallExprSyntax.self),
           parentCall.calledExpression.id == ExprSyntax(memberNode).id
        {
            return ExprSyntax(memberNode)
        }

        // Match .count property access
        guard memberNode.declName.baseName.text == "count" else { return ExprSyntax(memberNode) }

        // Base must be a .filter call
        guard let filterCall = memberNode.base?.as(FunctionCallExprSyntax.self),
              let filterAccess = filterCall.calledExpression.as(MemberAccessExprSyntax.self),
              filterAccess.declName.baseName.text == "filter" else {
            return ExprSyntax(memberNode)
        }

        // Extract the closure (trailing or inline single arg)
        let closure: ClosureExprSyntax

        if let trailingClosure = filterCall.trailingClosure {
            closure = trailingClosure
        } else if filterCall.arguments.count == 1,
           let closureExpr = filterCall.arguments.first?.expression.as(ClosureExprSyntax.self)
        {
            closure = closureExpr
        } else {
            return ExprSyntax(memberNode)
        }

        Self.diagnose(.preferCountWhere, on: filterAccess.declName, context: context)

        // Build: <originalBase>.count(where: { ... })
        let countAccess = MemberAccessExprSyntax(
            base: filterAccess.base,
            period: filterAccess.period,
            declName: DeclReferenceExprSyntax(baseName: .identifier("count"))
        )

        let whereArg = LabeledExprSyntax(
            label: .identifier("where"),
            colon: .colonToken(trailingTrivia: .space),
            expression: ExprSyntax(
                closure
                    .with(\.leadingTrivia, [])
                    .with(\.trailingTrivia, [])
            )
        )

        let countCall = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(countAccess),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([whereArg]),
            rightParen: .rightParenToken()
        )

        var result = ExprSyntax(countCall)
        result.leadingTrivia = memberNode.leadingTrivia
        result.trailingTrivia = memberNode.trailingTrivia
        return result
    }
}

fileprivate extension Finding.Message {
    static let preferCountWhere: Finding.Message = "prefer 'count(where:)' over 'filter(_:).count'"
}
