import SwiftSyntax

/// Prefer `contains(where:)` over `filter`-then-count/isEmpty/first patterns, and
/// `contains(_:)` over `range(of:) != nil`.
///
/// `filter` allocates an intermediate collection just to ask a yes/no question; `contains`
/// short-circuits at the first match. Likewise, `string.contains(needle)` is clearer and faster
/// than building a `Range` only to check it for `nil`.
///
/// Lint: warns on:
/// - `xs.filter { ... }.count [==/!=/>] 0`
/// - `xs.filter { ... }.isEmpty`
/// - `xs.first(where:) [==/!=] nil`, `xs.firstIndex(where:) [==/!=] nil`
/// - `s.range(of: needle) [==/!=] nil` (skipped when `options:` is supplied, e.g. `.regularExpression`)
final class PreferContains: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    // Pattern: `xs.filter { ... }.isEmpty`
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            node.declName.baseName.text == "isEmpty",
            let call = node.base?.as(FunctionCallExprSyntax.self),
            let calledMember = call.calledExpression.as(MemberAccessExprSyntax.self),
            calledMember.declName.baseName.text == "filter"
        else {
            return .visitChildren
        }
        diagnose(.containsOverFilterIsEmpty, on: calledMember.declName)
        return .visitChildren
    }

    // Patterns 1, 3, 4: comparisons via InfixOperatorExpr.
    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            let binOp = node.operator.as(BinaryOperatorExprSyntax.self)
        else {
            return .visitChildren
        }

        let opText = binOp.operator.text

        // Pattern 1: filter(_:).count <op> 0
        if ["==", "!=", ">"].contains(opText),
            node.rightOperand.as(IntegerLiteralExprSyntax.self)?.literal.text == "0",
            let countMember = node.leftOperand.as(MemberAccessExprSyntax.self),
            countMember.declName.baseName.text == "count",
            let filterCall = countMember.base?.as(FunctionCallExprSyntax.self),
            let filterMember = filterCall.calledExpression.as(MemberAccessExprSyntax.self),
            filterMember.declName.baseName.text == "filter"
        {
            diagnose(.containsOverFilterCount, on: filterMember.declName)
            return .visitChildren
        }

        // Patterns 3 & 4 require `<lhs> [==/!=] nil`.
        guard
            ["==", "!="].contains(opText),
            node.rightOperand.is(NilLiteralExprSyntax.self),
            let leftCall = node.leftOperand.as(FunctionCallExprSyntax.self),
            let leftMember = leftCall.calledExpression.as(MemberAccessExprSyntax.self)
        else {
            return .visitChildren
        }

        let methodName = leftMember.declName.baseName.text

        // Pattern 3: first(where:) / firstIndex(where:) <op> nil
        if methodName == "first" || methodName == "firstIndex" {
            diagnose(.containsOverFirstNotNil(method: methodName, op: opText), on: leftMember.declName)
            return .visitChildren
        }

        // Pattern 4: range(of:) <op> nil — skip if options/range arg is present
        if methodName == "range",
            leftCall.arguments.count == 1,
            leftCall.arguments.first?.label?.text == "of"
        {
            diagnose(.containsOverRangeNilComparison(op: opText), on: leftMember.declName)
        }

        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let containsOverFilterCount: Finding.Message =
        "prefer 'contains(where:)' over comparing 'filter(_:).count' to 0"

    fileprivate static let containsOverFilterIsEmpty: Finding.Message =
        "prefer 'contains(where:)' over 'filter(_:).isEmpty'"

    fileprivate static func containsOverFirstNotNil(method: String, op: String) -> Finding.Message {
        "prefer 'contains(where:)' over '\(method)(where:) \(op) nil'"
    }

    fileprivate static func containsOverRangeNilComparison(op: String) -> Finding.Message {
        "prefer 'contains' over 'range(of:) \(op) nil'"
    }
}
