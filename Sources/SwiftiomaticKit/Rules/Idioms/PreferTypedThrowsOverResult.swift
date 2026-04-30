import SwiftSyntax

/// Lint functions returning `Result<T, E>` whose body is a single
/// `do { return .success(...) } catch { return .failure(...) }`. The pattern
/// is mechanical — `throws(E) -> T` expresses the same contract more directly.
final class PreferTypedThrowsOverResult: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard returnsResult(node),
              let body = node.body,
              body.statements.count == 1,
              let firstItem = body.statements.first,
              let doStmt = firstItem.item.as(DoStmtSyntax.self),
              doStmt.catchClauses.count == 1,
              let catchClause = doStmt.catchClauses.first,
              endsWithSuccess(doStmt.body.statements),
              endsWithFailure(catchClause.body.statements)
        else {
            return .visitChildren
        }
        diagnose(.preferTypedThrows, on: node.name)
        return .visitChildren
    }

    private func returnsResult(_ node: FunctionDeclSyntax) -> Bool {
        guard let returnType = node.signature.returnClause?.type,
              let ident = returnType.as(IdentifierTypeSyntax.self),
              ident.name.text == "Result"
        else {
            return false
        }
        return true
    }

    private func endsWithSuccess(_ statements: CodeBlockItemListSyntax) -> Bool {
        endsWithReturnOfMember(statements, name: "success")
    }

    private func endsWithFailure(_ statements: CodeBlockItemListSyntax) -> Bool {
        endsWithReturnOfMember(statements, name: "failure")
    }

    private func endsWithReturnOfMember(_ statements: CodeBlockItemListSyntax, name: String) -> Bool {
        guard let last = statements.last,
              let returnStmt = last.item.as(ReturnStmtSyntax.self),
              let expression = returnStmt.expression
        else {
            return false
        }
        let callee: ExprSyntax
        if let call = expression.as(FunctionCallExprSyntax.self) {
            callee = call.calledExpression
        } else {
            callee = expression
        }
        guard let member = callee.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == name
        else {
            return false
        }
        return true
    }
}

extension Finding.Message {
    fileprivate static let preferTypedThrows: Finding.Message =
        "function returns 'Result<T, E>' via do/catch — express as 'throws(E) -> T' (typed throws)"
}
