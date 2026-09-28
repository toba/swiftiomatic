import SwiftSyntax

/// Check for cancellation in a loop that runs in async code.
///
/// Cancelling a task only sets a flag. A loop in async code keeps running after its task is
/// cancelled, unless it reads `Task.isCancelled` or calls `Task.checkCancellation()` . A long loop
/// then does work nobody waits for.
///
/// Check for cancellation at the start of each iteration. In a throwing context, call
/// `try Task.checkCancellation()`. In other code, write `guard !Task.isCancelled else { return }`
/// or `if Task.isCancelled { break }`. A loop that is short and ends quickly does not need a check.
///
/// Async code is the body of an `async` function, initializer or accessor, a closure that is marked
/// `async` or that awaits, a `Task { }` closure and its static factories, a task-group body and the
/// `.task` modifier.
///
/// A throwing await does not exempt the loop. A callee throws `CancellationError` only when it
/// checks for cancellation itself, and a `catch` in the loop can handle that error and go on. The
/// one exception is `try await Task.sleep(...)` outside a `do` / `catch` in the loop, which always
/// throws out of the loop when its task is cancelled. A `for try await` loop is exempt, because its
/// async sequence ends or throws when the task is cancelled. A short loop is exempt: it iterates
/// over an array literal or a range of integer literals, and it does not await.
///
/// Lint: A `for` , `while` or `repeat` loop in async code neither checks for cancellation nor
/// awaits `Task.sleep` .
final class RequireCancellationCheckInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.tryKeyword != nil, node.awaitKeyword != nil { return .visitChildren }

        if node.awaitKeyword == nil, node.sequence.isShortLiteralSequence, !node.body.awaitsDirectly
        { return .visitChildren }
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
        guard !scan.checksCancellation, !scan.sleeps else { return }
        diagnose(.uncheckedLoop(keyword.text), on: loop)
    }

    /// Finds a cancellation check anywhere in the loop and a `try await Task.sleep` outside any
    /// nested closure
    ///
    /// A cancellation check in a nested closure or function still counts, so this scanner enters
    /// them. A sleep in a nested function also counts. Only a sleep in a nested closure does not
    /// count.
    private final class AwaitScanner: DirectScopeVisitor {
        var checksCancellation = false
        var sleeps = false
        private var closureDepth = 0

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            closureDepth += 1
            return .visitChildren
        }

        override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

        override func visitPost(_: ClosureExprSyntax) { closureDepth -= 1 }

        /// The number of enclosing `do` statements with a `catch` inside the loop. A `catch` can
        /// handle the `CancellationError` of a sleep and let the loop go on.
        private var doCatchDepth = 0

        override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
            if !node.catchClauses.isEmpty { doCatchDepth += 1 }
            return .visitChildren
        }

        override func visitPost(_ node: DoStmtSyntax) {
            if !node.catchClauses.isEmpty { doCatchDepth -= 1 }
        }

        override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
            if closureDepth == 0,
               doCatchDepth == 0,
               let tryExpr = node.parent?.as(TryExprSyntax.self),
               tryExpr.questionOrExclamationMark == nil,
               Self.isTaskSleep(node.expression) { sleeps = true }
            return .visitChildren
        }

        /// Whether `expression` calls `Task.sleep`
        private static func isTaskSleep(_ expression: ExprSyntax) -> Bool {
            guard let call = expression.as(FunctionCallExprSyntax.self),
                  let access = call.calledExpression.as(MemberAccessExprSyntax.self),
                  access.declName.baseName.text == "sleep" else { return false }
            return access.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Task"
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
