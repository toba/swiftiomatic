import SwiftSyntax

/// Flag an `.onAppear` closure whose whole body is a `Task { }` .
///
/// `.onAppear` is synchronous, so the only way to start async work from it is an unstructured task.
/// That task outlives the view: nothing cancels it when the view goes away, and it keeps every
/// value it captured alive until it finishes. The `.task` modifier starts the same work and cancels
/// it when the view disappears.
///
/// The rule reports only the closure whose single statement is the task, because a closure that
/// also does synchronous work does not translate to `.task` on its own.
///
/// Lint: An `.onAppear` whose closure body is one `Task { }` raises a warning.
final class UseTaskModifierNotOnAppear: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "onAppear",
            let performed = performedClosure(of: node),
            let only = performed.statements.firstAndOnly,
            isTaskCall(only.item) else { return .visitChildren }

        diagnose(.useTaskModifier, on: member.declName)
        return .visitChildren
    }

    /// The closure the modifier runs, whether it arrives as a trailing closure or as `perform:` .
    private func performedClosure(of node: FunctionCallExprSyntax) -> ClosureExprSyntax? {
        if let trailing = node.trailingClosure { return trailing }
        return node.arguments.first { $0.label?.text == "perform" }?
            .expression.as(ClosureExprSyntax.self)
    }

    private func isTaskCall(_ item: CodeBlockItemSyntax.Item) -> Bool {
        guard case let .expr(expression) = item,
              let call = expression.as(FunctionCallExprSyntax.self),
              call.trailingClosure != nil else { return false }
        return call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Task"
    }
}

fileprivate extension Finding.Message {
    static let useTaskModifier: Finding.Message = """
        '.onAppear' that only starts a 'Task' leaks the task when the view goes away — use the \
        '.task' modifier, which cancels with the view
        """
}
