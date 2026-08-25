import SwiftSyntax

/// Flag `withUnsafeTemporaryAllocation` in favour of the span form added by SE-0524.
///
/// `withTemporaryAllocation` yields an `inout OutputSpan` or an `inout OutputRawSpan` instead of a
/// buffer pointer. The span tracks how many elements are initialised and deinitialises them on
/// every exit path, including a thrown error. The unsafe form leaves that bookkeeping to the
/// caller, and a missed `deinitialize()` leaks.
///
/// Lint: A call to `withUnsafeTemporaryAllocation` raises a warning.
final class UseSpanTemporaryAllocation: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let reference = node.calledExpression.as(DeclReferenceExprSyntax.self),
            reference.baseName.text == "withUnsafeTemporaryAllocation"
        else { return .visitChildren }

        diagnose(.useSpanAllocation, on: reference.baseName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useSpanAllocation: Finding.Message =
        "'withUnsafeTemporaryAllocation' hands you an uninitialised buffer — use 'withTemporaryAllocation' (SE-0524), which yields an 'OutputSpan' that deinitialises on every exit path"
}
