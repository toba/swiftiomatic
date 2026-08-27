import SwiftSyntax

/// Flag a timer that schedules outside the task tree.
///
/// `Timer.scheduledTimer` fires on a run loop, `Timer.publish` fires into a Combine pipeline, and
/// `DispatchSource.makeTimerSource` fires on a dispatch queue. None of the three is a child of the
/// task that made it, so cancelling that task leaves the timer running and the callback keeps its
/// captures alive. `AsyncTimerSequence` is an async sequence, so a `for await` loop over it ends
/// when the surrounding task is cancelled.
///
/// Lint: A call to `Timer.scheduledTimer` , `Timer.publish` or `DispatchSource.makeTimerSource`
/// raises a warning.
final class UseAsyncTimerSequence: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let base = node.base?.as(DeclReferenceExprSyntax.self) else { return .visitChildren }
        let member = node.declName.baseName.text

        switch (base.baseName.text, member) {
            case ("Timer", "scheduledTimer"),
                 ("Timer", "publish"),
                 ("DispatchSource", "makeTimerSource"):
                diagnose(
                    .useAsyncTimerSequence("\(base.baseName.text).\(member)"), on: node.declName)
            default: break
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func useAsyncTimerSequence(_ api: String) -> Finding.Message {
        """
        '\(api)' schedules outside the task tree, so nothing cancels it with the caller — use \
        'AsyncTimerSequence'
        """
    }
}
