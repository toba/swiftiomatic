import SwiftSyntax

/// Flag a checked or unsafe continuation in favour of the form added by SE-0528.
///
/// `withContinuation` yields a noncopyable `Continuation` . Consuming it on `resume` makes a second
/// resume a compile error rather than a runtime trap. A continuation the closure never resumes
/// traps at the point of failure instead of leaking the awaiting task forever.
///
/// Lint: A call to `withCheckedContinuation` , `withUnsafeContinuation` ,
/// `withCheckedThrowingContinuation` or `withUnsafeThrowingContinuation` raises a warning.
final class UseContinuationNotChecked: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private static let supersededNames: Set<String> = [
        "withCheckedContinuation",
        "withCheckedThrowingContinuation",
        "withUnsafeContinuation",
        "withUnsafeThrowingContinuation",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // a member call names someone else's method, not the stdlib free function
        guard let reference = node.calledExpression.as(DeclReferenceExprSyntax.self),
            Self.supersededNames.contains(reference.baseName.text) else { return .visitChildren }

        diagnose(.useContinuation, on: reference.baseName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useContinuation: Finding.Message =
        "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"
}
