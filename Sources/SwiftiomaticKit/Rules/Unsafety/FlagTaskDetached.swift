import SwiftSyntax

/// Flag `Task.detached(...)` calls. `Task.detached` opts out of structured concurrency: the
/// child does not inherit the parent's actor isolation, priority, or `@TaskLocal` values, and
/// is not awaited by the surrounding scope. In Swift 6 the supported alternatives are
/// `@concurrent` functions (when off-actor execution is the goal) and `Task.immediateDetached`
/// (when the goal is just to escape the current actor without an inherited task tree).
///
/// Flag-only — replacing `Task.detached` requires deciding whether `@TaskLocal` inheritance,
/// priority pinning, or cancellation-tree behavior matters at the call site.
final class FlagTaskDetached: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "detached",
              let base = member.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.text == "Task" else { return .visitChildren }
        diagnose(.taskDetached, on: member.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let taskDetached: Finding.Message =
        "'Task.detached' breaks structured concurrency and drops '@TaskLocal' inheritance — use a '@concurrent' function or 'Task.immediateDetached' instead"
}
