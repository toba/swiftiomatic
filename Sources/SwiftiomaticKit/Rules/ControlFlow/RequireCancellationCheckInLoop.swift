import SwiftSyntax

/// Check for cancellation in a loop that awaits inside a task.
///
/// Cancelling a task only sets a flag. A loop that awaits on each pass keeps running after its task
/// is cancelled, unless it reads `Task.isCancelled` or calls `Task.checkCancellation()` . A long
/// loop then does work nobody waits for.
///
/// The rule looks at loops inside `Task { }` , its static factories and the `.task` modifier. A
/// `for await` loop over an async sequence is exempt, because the sequence usually ends when its
/// task is cancelled. So is a loop with a `try await` , because a throwing call usually throws
/// `CancellationError` .
///
/// Lint: A `for` , `while` or `repeat` loop inside a task closure awaits, and neither checks for
/// cancellation nor makes a throwing await.
final class RequireCancellationCheckInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.awaitKeyword == nil { check(node, keyword: node.forKeyword) }
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        check(node, keyword: node.whileKeyword)
        return .visitChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        check(node, keyword: node.repeatKeyword)
        return .visitChildren
    }

    private func check(_ loop: some SyntaxProtocol, keyword: TokenSyntax) {
        guard Self.isInTaskClosure(loop) else { return }
        let scan = AwaitScanner(viewMode: .sourceAccurate)
        scan.walk(loop)
        guard scan.awaits, !scan.checksCancellation, !scan.throwingAwait else { return }
        diagnose(.uncheckedLoop(keyword.text), on: loop)
    }

    /// Whether a closure that runs as a task encloses `node` inside the same declaration
    private static func isInTaskClosure(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let syntax = current {
            if syntax.is(FunctionDeclSyntax.self) || syntax.is(InitializerDeclSyntax.self)
                || syntax.is(AccessorDeclSyntax.self) { return false }

            if let closure = syntax.as(ClosureExprSyntax.self), let call = closure.owningCall {
                if call.createsUnstructuredTask { return true }

                if call.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
                    == "task" { return true }
            }
            current = syntax.parent
        }
        return false
    }

    private final class AwaitScanner: SyntaxVisitor {
        var awaits = false
        var checksCancellation = false
        var throwingAwait = false

        override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
            awaits = true

            if let tryExpr = node.parent?.as(TryExprSyntax.self), tryExpr.questionOrExclamationMark == nil {
                throwingAwait = true
            }
            return .visitChildren
        }

        override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
            let name = node.baseName.text
            if name == "isCancelled" || name == "checkCancellation" { checksCancellation = true }
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func uncheckedLoop(_ keyword: String) -> Finding.Message {
        "'\(keyword)' loop awaits inside a task but never checks for cancellation. Check 'Task.isCancelled' or call 'Task.checkCancellation()' in the loop"
    }
}
