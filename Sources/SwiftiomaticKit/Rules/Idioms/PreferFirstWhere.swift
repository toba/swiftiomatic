import SwiftSyntax

/// Prefer `.first(where:)` over `.filter { ... }.first`.
///
/// `filter` allocates and populates an entire intermediate array; `first(where:)` short-circuits
/// at the first match.
///
/// Lint: `xs.filter { ... }.first` raises a warning suggesting `first(where:)`.
final class PreferFirstWhere: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            node.declName.baseName.text == "first",
            let call = node.base?.as(FunctionCallExprSyntax.self),
            let calledMember = call.calledExpression.as(MemberAccessExprSyntax.self),
            calledMember.declName.baseName.text == "filter",
            !call.arguments.contains(where: { $0.expression.shouldSkipFilterShortCircuit })
        else {
            return .visitChildren
        }
        diagnose(.preferFirstWhere, on: calledMember.declName)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let preferFirstWhere: Finding.Message =
        "prefer 'first(where:)' over 'filter(_:).first'"
}

extension ExprSyntax {
    /// Skip filter expressions whose argument is a string literal predicate or `NSPredicate(...)`,
    /// since these forms often imply Realm/Core Data lazy collections where `first(where:)` is not
    /// equivalent.
    fileprivate var shouldSkipFilterShortCircuit: Bool {
        if self.is(StringLiteralExprSyntax.self) { return true }
        if let call = self.as(FunctionCallExprSyntax.self),
            call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSPredicate"
        {
            return true
        }
        return false
    }
}
