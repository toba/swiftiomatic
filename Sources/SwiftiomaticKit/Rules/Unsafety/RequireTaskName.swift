import SwiftSyntax

/// Require a `name:` argument when starting a `Task` or adding work to a `TaskGroup`. Swift 6.2
/// (Xcode 26 / macOS 26 / iOS 26) added `name:` overloads to `Task.init`, `Task.detached`,
/// `Task.immediate`, `Task.immediateDetached`, `TaskGroup.addTask`, and
/// `TaskGroup.addTaskUnlessCancelled`. The name shows up in Instruments' Swift Concurrency
/// instrument, in the Xcode debugger's task list, and in custom `Task.currentName` reads —
/// unnamed tasks are anonymous and indistinguishable from one another there.
///
/// `addTask` and `addTaskUnlessCancelled` fire only when the call has the shape of the task-group
/// method: the work arrives as a trailing closure or a final `operation:` argument, and every
/// other argument carries a label the task-group method accepts. An unrelated method with the
/// same base name stays quiet.
///
/// Flag-only — the fix requires picking a meaningful name.
///
/// See https://artemnovichkov.com/blog/task-names-in-swift-concurrency.
final class RequireTaskName: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let kind = taskCallKind(node) else { return .visitChildren }
        guard !hasNameArgument(node) else { return .visitChildren }
        diagnose(kind.message, on: kind.anchor)
        return .visitChildren
    }

    private struct TaskCall {
        let anchor: Syntax
        let message: Finding.Message
    }

    /// Classifies the call as one of the Task-spawning APIs that gained a `name:` overload in
    /// Swift 6.2. Returns nil for anything else.
    private func taskCallKind(_ node: FunctionCallExprSyntax) -> TaskCall? {
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ident.baseName.text == "Task"
        {
            return TaskCall(anchor: Syntax(ident), message: .taskInitMissingName)
        }
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
            let name = member.declName.baseName.text
            if let base = member.base?.as(DeclReferenceExprSyntax.self),
               base.baseName.text == "Task",
               name == "detached" || name == "immediate" || name == "immediateDetached"
            {
                return TaskCall(anchor: Syntax(member.declName), message: .taskStaticMissingName(name))
            }
            if name == "addTask" || name == "addTaskUnlessCancelled", looksLikeTaskGroupAddTask(node) {
                return TaskCall(anchor: Syntax(member.declName), message: .addTaskMissingName(name))
            }
        }
        return nil
    }

    /// The labels `TaskGroup.addTask` accepts. Every other label means the call is some other
    /// method that happens to share the base name.
    private static let taskGroupLabels: Set<String> = [
        "name", "executorPreference", "priority", "operation",
    ]

    /// Reports whether the call has the shape of `TaskGroup.addTask` .
    ///
    /// The receiver's type is unavailable in the syntax tree, so the check works from the
    /// argument list instead. A task-group call passes its work as a trailing closure or as a
    /// final `operation:` argument, and labels every other argument from a short known set.
    private func looksLikeTaskGroupAddTask(_ node: FunctionCallExprSyntax) -> Bool {
        let labels = node.arguments.compactMap { $0.label?.text }
        guard labels.count == node.arguments.count else { return false }
        guard labels.allSatisfy(Self.taskGroupLabels.contains) else { return false }
        if node.trailingClosure != nil { return true }
        return labels.last == "operation"
    }

    private func hasNameArgument(_ node: FunctionCallExprSyntax) -> Bool {
        node.arguments.contains { $0.label?.text == "name" }
    }
}

fileprivate extension Finding.Message {
    static let taskInitMissingName: Finding.Message =
        "'Task { ... }' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
    static func taskStaticMissingName(_ name: String) -> Finding.Message {
        "'Task.\(name)' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
    }
    static func addTaskMissingName(_ name: String) -> Finding.Message {
        "'\(name)' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
    }
}
