import SwiftSyntax

/// Collects thrown error types from throw expressions. Used by both
/// `TypedThrowsCheck` (suggest) and `TypedThrowsRule` (lint).
final class ThrowCollector: SyntaxVisitor {
    var thrownTypes: Set<String> = []
    var hasRethrows = false
    /// Byte offsets of throw expressions with unknown types (for SourceKit resolution).
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
