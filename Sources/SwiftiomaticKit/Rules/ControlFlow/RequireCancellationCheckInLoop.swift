import SwiftSyntax

/// Check for cancellation in a loop that runs in async code.
///
/// Cancelling a task only sets a flag. A loop in async code keeps running after its task is
/// cancelled, unless it reads `Task.isCancelled` or calls `Task.checkCancellation()` . A long loop
/// then does work nobody waits for.
///
/// Async code is the body of an `async` function, initializer or accessor, a closure that is
/// marked `async` or that awaits, a `Task { }` closure and its static factories, a task-group body
/// and the `.task` modifier. A loop with a `try await` in its own body is exempt, because a
/// throwing call usually throws `CancellationError` . A `for try await` loop is exempt for the same
/// reason. A short loop is exempt: it iterates over an array literal or a range of integer
/// literals, and it does not await.
///
/// Lint: A `for` , `while` or `repeat` loop in async code neither checks for cancellation nor
/// makes a throwing await.
final class RequireCancellationCheckInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.tryKeyword != nil, node.awaitKeyword != nil { return .visitChildren }
        if node.awaitKeyword == nil, node.sequence.isShortLiteralSequence, !node.body.awaitsDirectly {
            return .visitChildren
        }
        check(node, keyword: node.forKeyword)
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
        guard loop.isInAsyncContext else { return }
        let scan = AwaitScanner(viewMode: .sourceAccurate)
        scan.walk(loop)
        guard !scan.checksCancellation, !scan.throwingAwait else { return }
        diagnose(.uncheckedLoop(keyword.text), on: loop)
    }

    /// Finds a cancellation check anywhere in the loop and a throwing await outside any nested
    /// closure
    ///
    /// A cancellation check in a nested closure or function still counts, so this scanner enters
    /// them. A throwing await in a nested function also counts. Only a throwing await in a nested
    /// closure does not count.
    private final class AwaitScanner: DirectScopeVisitor {
        var checksCancellation = false
        var throwingAwait = false
        private var closureDepth = 0

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            closureDepth += 1
            return .visitChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) { closureDepth -= 1 }

        override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
            if closureDepth == 0, let tryExpr = node.parent?.as(TryExprSyntax.self),
               tryExpr.questionOrExclamationMark == nil
            {
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
        "'\(keyword)' loop runs in async code but never checks for cancellation. Check 'Task.isCancelled' or call 'Task.checkCancellation()' in the loop"
    }
}
