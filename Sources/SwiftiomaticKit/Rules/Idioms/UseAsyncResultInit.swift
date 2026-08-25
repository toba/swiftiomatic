import SwiftSyntax

/// Flag a `do` / `catch` that exists only to wrap async work in a `Result` .
///
/// SE-0530 adds an async `Result.init(catching:)` , so the whole block collapses to
/// `await Result { try await work() }` . The long form repeats the target on three lines and lets
/// the two assignments drift apart.
///
/// The rule fires only when the `.success` value awaits. The synchronous `Result(catching:)`
/// already existed, and a synchronous `do` / `catch` is often doing more than building a `Result` .
///
/// Lint: A `do` block whose last statement assigns `.success` of an awaited value, paired with a
/// single `catch` that assigns `.failure` to the same target, raises a warning.
final class UseAsyncResultInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        guard let catchClause = node.catchClauses.firstAndOnly,
              catchClause.catchItems.isEmpty,
              let successTarget = node.body.statements.last?.resultAssignmentTarget(
                  case: "success"),
              let failureTarget = catchClause.body.statements.firstAndOnly?
                  .resultAssignmentTarget(case: "failure"),
              successTarget.target == failureTarget.target,
              successTarget.value.containsAwait else { return .visitChildren }

        diagnose(.useAsyncResultInit, on: node.doKeyword)
        return .visitChildren
    }
}

fileprivate extension CodeBlockItemSyntax {
    /// The target and the payload of an assignment shaped `x = .<caseName>(payload)` .
    func resultAssignmentTarget(case caseName: String) -> (target: String, value: ExprSyntax)? {
        guard case let .expr(expression) = item,
              let assignment = expression.as(InfixOperatorExprSyntax.self),
              assignment.operator.is(AssignmentExprSyntax.self),
              let call = assignment.rightOperand.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base == nil,
              member.declName.baseName.text == caseName,
              let payload = call.arguments.firstAndOnly else { return nil }

        return (assignment.leftOperand.trimmedDescription, payload.expression)
    }
}

fileprivate extension ExprSyntax {
    /// Whether the expression awaits anywhere inside it.
    var containsAwait: Bool {
        tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.await) }
    }
}

fileprivate extension Finding.Message {
    static let useAsyncResultInit: Finding.Message =
        "this 'do'/'catch' only builds a 'Result' — collapse it to 'await Result { try await … }' (SE-0530)"
}
