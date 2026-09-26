import SwiftSyntax

/// Pass an explicit `priority:` when starting an unstructured task.
///
/// `Task { }` inherits the priority of its caller, and `Task.detached { }` runs at the default
/// priority. Neither default states how urgent the work is. An explicit priority lets the scheduler
/// run user-facing work first and background work last.
///
/// The rule fires in every context, including SwiftUI views and `@MainActor` code. A task that a
/// view starts often does persistence or network work whose urgency differs from the UI event that
/// started it. Keep the inherited priority only when the task must run at its caller's priority,
/// and suppress the finding there.
///
/// Lint: An unstructured task (`Task { }`, `Task.immediate { }`, `Task.detached { }` or
/// `Task.immediateDetached { }`) with no `priority:` argument raises a warning.
final class RequireTaskPriority: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.createsUnstructuredTask, let call = node.taskCall,
              !node.arguments.contains(where: { $0.label?.text == "priority" })
        else { return .visitChildren }

        if let factory = call.factory, let token = call.factoryToken {
            diagnose(.taskStaticMissingPriority(factory), on: token)
        } else {
            diagnose(.taskInitMissingPriority, on: call.anchor)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let taskInitMissingPriority: Finding.Message =
        "'Task { ... }' has no priority; pass 'priority:' to state how urgent the work is"
    static func taskStaticMissingPriority(_ name: String) -> Finding.Message {
        "'Task.\(name)' has no priority; pass 'priority:' to state how urgent the work is"
    }
}
