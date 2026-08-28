import SwiftSyntax

/// Lint elapsed-time uses of `Date()` / `Date.now` — prefer `ContinuousClock` .
///
/// Patterns flagged:
/// - `Date().timeIntervalSince(start)` / `Date.now.timeIntervalSince(start)`
/// - `Date().timeIntervalSinceNow` / `Date.now.timeIntervalSinceNow`
///
/// `ContinuousClock.now` (paired with `start.duration(to: .now)` or `clock.measure { … }` ) is
/// monotonic, allocation-free, and unaffected by wall-clock adjustments.
///
/// Lint-only: autofixing requires rewriting the start-time site as well, which is outside the
/// rule's single-node scope.
final class UseContinuousClockNotDate: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "timeIntervalSince",
            let base = member.base,
            isDateNowExpression(base) { diagnose(.preferContinuousClock, on: node) }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // Only the property form: `Date().timeIntervalSinceNow` . Skip the member when it's the
        // callee of a function call (handled above).
        if node.parent?.is(FunctionCallExprSyntax.self) == true { return .visitChildren }
        if node.declName.baseName.text == "timeIntervalSinceNow",
           let base = node.base,
           isDateNowExpression(base) { diagnose(.preferContinuousClock, on: node) }
        return .visitChildren
    }

    /// Matches `Date()` (zero-arg initializer call) or `Date.now` .
    private func isDateNowExpression(_ expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self),
           call.arguments.isEmpty,
           let ident = call.calledExpression.as(DeclReferenceExprSyntax.self),
           ident.baseName.text == "Date" { return true }
        if let member = expr.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "now",
           let base = member.base?.as(DeclReferenceExprSyntax.self),
           base.baseName.text == "Date" { return true }
        return false
    }
}

fileprivate extension Finding.Message {
    static let preferContinuousClock: Finding.Message =
        "elapsed time uses 'Date()' — prefer 'ContinuousClock.now' + 'duration(to:)' (monotonic, allocation-free)"
}
