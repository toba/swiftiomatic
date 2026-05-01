import SwiftSyntax

/// Lint the `if !collection.contains(x) { collection.append(x) }` pattern.
///
/// Maintaining uniqueness in an `Array` via `contains` + `append` is O(n) per insertion.
/// `OrderedSet` (swift-collections) preserves insertion order with O(1) average insertion and
/// `contains` .
///
/// Lint-only: rewriting would change the variable's declared type, which is outside the rule's
/// structural scope.
final class UseOrderedSetForUniqueAppend: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.conditions.count == 1,
              let firstCondition = node.conditions.first,
              case let .expression(conditionExpr) = firstCondition.condition,
              let prefix = conditionExpr.as(PrefixOperatorExprSyntax.self),
              prefix.operator.tokenKind == .prefixOperator("!"),
              let containsCall = prefix.expression.as(FunctionCallExprSyntax.self),
              let containsMember = containsCall.calledExpression.as(MemberAccessExprSyntax.self),
              containsMember.declName.baseName.text == "contains",
              containsCall.arguments.count == 1,
              let containsArg = containsCall.arguments.first?.expression,
              let collectionExpr = containsMember.base else { return .visitChildren }

        guard node.body.statements.count == 1,
              let onlyStmt = node.body.statements.first,
              let appendCallExpr = ExprSyntax(onlyStmt.item),
              let appendCall = appendCallExpr.as(FunctionCallExprSyntax.self),
              let appendMember = appendCall.calledExpression.as(MemberAccessExprSyntax.self),
              appendMember.declName.baseName.text == "append",
              appendCall.arguments.count == 1,
              let appendArg = appendCall.arguments.first?.expression,
              let appendCollectionExpr = appendMember.base else { return .visitChildren }

        guard sameExpression(collectionExpr, appendCollectionExpr),
              sameExpression(containsArg, appendArg) else { return .visitChildren }

        diagnose(.suggestOrderedSet, on: node)
        return .visitChildren
    }

    private func sameExpression(_ a: ExprSyntax, _ b: ExprSyntax) -> Bool {
        a.trimmedDescription == b.trimmedDescription
    }
}

fileprivate extension Finding.Message {
    static let suggestOrderedSet: Finding.Message =
        "'!contains' + 'append' guards uniqueness in O(n) — consider 'OrderedSet' from swift-collections"
}
