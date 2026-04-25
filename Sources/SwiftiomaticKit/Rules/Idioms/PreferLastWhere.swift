import SwiftSyntax

/// Prefer `.last(where:)` over `.filter { ... }.last`.
///
/// `filter` allocates and populates an entire intermediate array; `last(where:)` walks the
/// collection once and avoids the allocation.
///
/// Lint: `xs.filter { ... }.last` raises a warning suggesting `last(where:)`.
final class PreferLastWhere: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            node.declName.baseName.text == "last",
            let call = node.base?.as(FunctionCallExprSyntax.self),
            let calledMember = call.calledExpression.as(MemberAccessExprSyntax.self),
            calledMember.declName.baseName.text == "filter",
            !call.arguments.contains(where: { $0.expression.isFilterArgumentSkipped })
        else {
            return .visitChildren
        }
        diagnose(.preferLastWhere, on: calledMember.declName)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let preferLastWhere: Finding.Message =
        "prefer 'last(where:)' over 'filter(_:).last'"
}

extension ExprSyntax {
    fileprivate var isFilterArgumentSkipped: Bool {
        if self.is(StringLiteralExprSyntax.self) { return true }
        if let call = self.as(FunctionCallExprSyntax.self),
            call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSPredicate"
        {
            return true
        }
        return false
    }
}
