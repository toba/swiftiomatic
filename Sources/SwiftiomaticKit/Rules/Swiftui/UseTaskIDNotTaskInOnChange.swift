import SwiftSyntax

/// Flag a `Task` that starts inside the action closure of `.onChange(of:)` .
///
/// The action closure is synchronous, so it can start async work only as an unstructured task.
/// Nothing cancels that task when the value changes again, so two tasks for two values can run at
/// the same time and finish in the wrong order. Nothing cancels it when the view goes away either.
///
/// `.task(id:)` with the same value runs the work when the view appears and each time the value
/// changes. It cancels the previous run first, and it cancels the last run with the view.
///
/// The rule reports a `Task` , `Task.immediate` , `Task.detached` or `Task.immediateDetached`
/// call in the action closure, including one inside an `if` or `switch` . A task inside a nested
/// closure, such as a `Button` action, runs from that closure and is not reported.
///
/// Lint: An `.onChange(of:)` action closure starts a `Task` .
final class UseTaskIDNotTaskInOnChange: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onChange",
              node.arguments.contains(where: { $0.label?.text == "of" }),
              let action = node.actionClosure(labels: ["action"]) else { return .visitChildren }
        let finder = TaskFinder(viewMode: .sourceAccurate)
        finder.walk(action.statements)

        for task in finder.tasks { diagnose(.useTaskID, on: task) }
        return .visitChildren
    }

    /// Finds the task calls of one closure body and does not enter nested closures
    private final class TaskFinder: SyntaxVisitor {
        var tasks: [FunctionCallExprSyntax] = []

        /// Records `Task { }` , `Task<T, E> { }` and each factory in
        /// `FunctionCallExprSyntax.taskFactories` , with or without arguments. Another member such
        /// as `Task.yield()` does not start a task.
        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let task = node.taskCall,
                  task.factory.map({ FunctionCallExprSyntax.taskFactories.contains($0) }) ?? true
            else { return .visitChildren }
            tasks.append(node)
            return .skipChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    }
}

fileprivate extension Finding.Message {
    static let useTaskID: Finding.Message = """
        a 'Task' started in '.onChange(of:)' is not cancelled when the value changes again or the \
        view goes away. Use '.task(id:)' with the same value
        """
}
