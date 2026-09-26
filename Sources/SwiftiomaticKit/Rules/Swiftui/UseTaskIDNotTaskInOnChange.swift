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
/// The rule reports a `Task` , `Task.immediate` or `Task.detached` call in the action closure,
/// including one inside an `if` or `switch` . A task inside a nested closure, such as a `Button`
/// action, runs from that closure and is not reported.
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
        static let taskFactories: Set<String> = ["immediate", "detached"]

        var tasks: [FunctionCallExprSyntax] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard Self.isTaskCall(node) else { return .visitChildren }
            tasks.append(node)
            return .skipChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        /// Whether `node` is `Task { }` , `Task<T, E> { }` , `Task.immediate { }` or
        /// `Task.detached { }` , with or without arguments
        private static func isTaskCall(_ node: FunctionCallExprSyntax) -> Bool {
            var callee = node.calledExpression

            if let member = callee.as(MemberAccessExprSyntax.self), let base = member.base {
                guard taskFactories.contains(member.declName.baseName.text) else { return false }
                callee = base
            }
            if let generic = callee.as(GenericSpecializationExprSyntax.self) {
                callee = generic.expression
            }
            return callee.as(DeclReferenceExprSyntax.self)?.baseName.text == "Task"
        }
    }
}

fileprivate extension Finding.Message {
    static let useTaskID: Finding.Message = """
        a 'Task' started in '.onChange(of:)' is not cancelled when the value changes again or the \
        view goes away. Use '.task(id:)' with the same value
        """
}
