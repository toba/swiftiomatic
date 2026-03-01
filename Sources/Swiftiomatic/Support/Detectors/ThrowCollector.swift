import SwiftSyntax

/// Collects thrown error types from `throw` expressions within a single function scope
///
/// Stops at closure and nested function boundaries since those have their own
/// throw scope. Used by both `TypedThrowsCheck` (suggest) and `TypedThrowsRule` (lint).
final class ThrowCollector: SyntaxVisitor {
    /// Distinct error type names found in `throw` statements
    var thrownTypes: Set<String> = []

    /// Whether the body contains an unqualified `try` (indicating rethrown errors)
    var hasRethrows = false

    /// Byte offsets of `throw` expressions whose type could not be determined statically
    var unknownOffsets: [Int] = []

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        let expr = node.expression

        if let memberAccess = expr.as(MemberAccessExprSyntax.self),
           let base = memberAccess.base
        {
            thrownTypes.insert(base.trimmedDescription)
        } else if let funcCall = expr.as(FunctionCallExprSyntax.self) {
            thrownTypes.insert(funcCall.calledExpression.trimmedDescription)
        } else {
            thrownTypes.insert("__unknown__")
            unknownOffsets.append(expr.positionAfterSkippingLeadingTrivia.utf8Offset)
        }

        return .skipChildren
    }

    override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
        if node.questionOrExclamationMark == nil {
            hasRethrows = true
        }
        return .visitChildren
    }

    /// Don't descend into nested closures/functions — they have their own throw scope.
    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
