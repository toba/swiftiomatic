import SwiftSyntax

/// Yield to other tasks in a long loop that runs in async code.
///
/// A task gives up its thread only at a suspension point. A loop in async code that makes only
/// synchronous calls keeps its thread for every pass. Other tasks on the same executor then wait
/// until the loop ends. A call to `await Task.yield()` in the loop lets them run.
///
/// Async code is the body of an `async` function, initializer or accessor, a closure that is
/// marked `async` or that awaits, a `Task { }` closure and its static factories, a task-group body
/// and the `.task` modifier. A loop that awaits in its own body is exempt, because it already
/// suspends. A `for await` loop is exempt for the same reason. A short loop is exempt: it iterates
/// over an array literal or a range of integer literals. A loop body that makes no call is exempt,
/// because its passes are cheap. A yield has a cost, so apply this advice only to a loop that can
/// run for a long time.
///
/// Lint: A `for` , `while` or `repeat` loop in async code makes a call on each pass and never
/// awaits.
final class RequireTaskYieldInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        guard node.awaitKeyword == nil, !node.sequence.isShortLiteralSequence else {
            return .visitChildren
        }
        check(node, body: node.body, keyword: node.forKeyword)
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        guard !node.conditions.awaitsDirectly else { return .visitChildren }
        check(node, body: node.body, keyword: node.whileKeyword)
        return .visitChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        guard !node.condition.awaitsDirectly else { return .visitChildren }
        check(node, body: node.body, keyword: node.repeatKeyword)
        return .visitChildren
    }

    private func check(_ loop: some SyntaxProtocol, body: CodeBlockSyntax, keyword: TokenSyntax) {
        guard !body.awaitsDirectly, loop.isInAsyncContext else { return }
        let scan = DirectCallScanner(viewMode: .sourceAccurate)
        scan.walk(body)
        guard scan.calls else { return }
        diagnose(.loopNeverYields(keyword.text), on: loop)
    }

    /// Finds a function call that is not inside a nested closure or function.
    private final class DirectCallScanner: DirectScopeVisitor {
        var calls = false

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            calls = true
            return .skipChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func loopNeverYields(_ keyword: String) -> Finding.Message {
        "'\(keyword)' loop in async code makes calls with no suspension point. Call 'await Task.yield()' in the loop so other tasks can run"
    }
}
