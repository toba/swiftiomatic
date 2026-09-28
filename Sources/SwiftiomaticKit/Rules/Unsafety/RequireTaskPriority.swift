import SwiftSyntax

/// Pass an explicit `priority:` when starting a detached task.
///
/// `Task.detached { }` and `Task.immediateDetached { }` do not inherit the priority of the code
/// that starts them. They run at the default priority, whatever the urgency of the caller. An
/// explicit priority lets the scheduler run user-facing work first and background work last. For
/// example, change `Task.detached { await sync() }` to
/// `Task.detached(priority: .background) { await sync() }`.
///
/// `Task { }` and `Task.immediate { }` inherit the priority of the caller, so the rule does not
/// report them. Keep them without a priority when the work runs at the caller's priority, and pass
/// `priority:` when the urgency of the work differs from that of the caller.
///
/// Lint: A `Task.detached { }` or `Task.immediateDetached { }` call with no `priority:` argument
/// raises a warning.
final class RequireTaskPriority: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }
    override class var guidance: GuidanceLevel { .consider }

    /// The task factories that do not inherit the priority of the caller
    private static let detachedFactories: Set<String> = ["detached", "immediateDetached"]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.createsUnstructuredTask,
              let call = node.taskCall,
              let factory = call.factory,
              Self.detachedFactories.contains(factory),
              let token = call.factoryToken,
              !node.arguments.contains(where: { $0.label?.text == "priority" })
        else { return .visitChildren }

        diagnose(.detachedMissingPriority(factory), on: token)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func detachedMissingPriority(_ name: String) -> Finding.Message {
        "'Task.\(name)' does not inherit the priority of its caller. Pass 'priority:' to state how urgent the work is"
    }
}
