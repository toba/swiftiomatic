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
/// When the action calls a method that starts the task, make that method `async` and await it from
/// `.task(id:)` . A stored task handle that the action cancels before it starts the next task does
/// not solve the problem: nothing cancels the last task when the view goes away. Work that must
/// outlive the view, such as a write to a service, belongs to a model or service that owns it.
///
/// The rule reports a `Task` , `Task.immediate` , `Task.detached` or `Task.immediateDetached` call
/// in the action closure, including one inside an `if` or `switch` . It also reports a call in the
/// action to a method of the same type that starts such a task, directly or through other methods
/// of the type. A task inside a nested closure, such as a `Button` action, runs from that closure
/// and is not reported.
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
        guard !finder.helperCalls.isEmpty,
              let entry = context.typeMembers(around: node).enclosingType(of: node)
        else { return .visitChildren }

        for (name, call) in finder.helperCalls {
            var visited: Set<String> = []

            if Self.startsTask(name, in: entry, visited: &visited) {
                diagnose(.helperStartsTask(name), on: call)
            }
        }
        return .visitChildren
    }

    /// Whether the method `name` of `entry` starts a task, directly or through other methods of
    /// `entry`
    ///
    /// `visited` holds the methods already checked, so a recursive call ends the walk.
    private static func startsTask(
        _ name: String,
        in entry: TypeMemberIndex.TypeEntry,
        visited: inout Set<String>
    ) -> Bool {
        guard visited.insert(name).inserted else { return false }

        for member in entry.members(named: name) ?? [] where member.kind == .method {
            guard let body = member.body else { continue }
            let finder = TaskFinder(viewMode: .sourceAccurate)
            finder.walk(body)
            if !finder.tasks.isEmpty { return true }

            for (
                helper, _
            ) in finder.helperCalls
                where startsTask(helper, in: entry, visited: &visited)
            { return true }
        }
        return false
    }

    /// Finds the task calls of one closure body and does not enter nested closures
    private final class TaskFinder: SyntaxVisitor {
        var tasks: [FunctionCallExprSyntax] = []

        /// Calls to a method of the same type, as `name()` or `self.name()` , by method name
        var helperCalls: [(name: String, call: FunctionCallExprSyntax)] = []

        /// Records `Task { }` , `Task<T, E> { }` and each factory in
        /// `FunctionCallExprSyntax.taskFactories` , with or without arguments. Another member such
        /// as `Task.yield()` does not start a task.
        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let task = node.taskCall,
                  task.factory.map({ FunctionCallExprSyntax.taskFactories.contains($0) }) ?? true
            else {
                if let name = Self.ownMethodName(of: node) { helperCalls.append((name, node)) }
                return .visitChildren
            }
            tasks.append(node)
            return .skipChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        /// The method name of a call on the same instance: `name()` or `self.name()`
        private static func ownMethodName(of call: FunctionCallExprSyntax) -> String? {
            if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
                return reference.baseName.text
            }
            guard let access = call.calledExpression.as(MemberAccessExprSyntax.self),
                access.base?.as(DeclReferenceExprSyntax.self)?.baseName
                    .tokenKind
                    == .keyword(.self) else { return nil }
            return access.declName.baseName.text
        }
    }
}

fileprivate extension Finding.Message {
    static let useTaskID: Finding.Message = """
        a 'Task' started in '.onChange(of:)' is not cancelled when the value changes again or the \
        view goes away. Use '.task(id:)' with the same value
        """

    static func helperStartsTask(_ helper: String) -> Finding.Message {
        """
        '\(helper)' starts a 'Task' that '.onChange(of:)' does not cancel when the value changes \
        again or the view goes away. Make the work async and await it from '.task(id:)' with the \
        same value
        """
    }
}
