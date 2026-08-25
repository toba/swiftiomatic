import SwiftSyntax

/// A call whose callee names the `Task` type.
///
/// Rules disagree on purpose about which forms they act on. `FlagTaskInMainActor` wants the
/// initializer alone, `FlagTaskDetached` wants one factory, and `RequireTaskName` wants both. So
/// this type reports what the call is and leaves the filtering to the caller.
struct TaskCall {
    /// The `Task` token, for a rule that anchors its finding on the type name.
    let anchor: TokenSyntax
    /// The factory name in `Task.<name> { }` , or `nil` for `Task { }` .
    let factory: String?
    /// The token naming the factory, for a rule that anchors there instead of on `Task` .
    let factoryToken: TokenSyntax?
    /// The generic arguments of `Task<Success, Failure> { }` , when the author wrote them.
    let genericArguments: GenericArgumentClauseSyntax?
}

extension FunctionCallExprSyntax {
    /// The names of the `Task` static factories that also produce an unstructured task.
    static let taskFactories: Set<String> = ["detached", "immediate", "immediateDetached"]

    /// This call's reference to the `Task` type, or `nil` when the callee names something else.
    ///
    /// Recognises `Task { }` , `Task<Success, Failure> { }` and `Task.<factory> { }` . A member
    /// access that is not one of `taskFactories` still reports, because `Task.isCancelled` and
    /// `Task.yield()` are legitimate matches for a rule that wants them. Filter on `factory` .
    var taskCall: TaskCall? {
        if let reference = calledExpression.as(DeclReferenceExprSyntax.self) {
            guard reference.baseName.text == "Task" else { return nil }
            return TaskCall(
                anchor: reference.baseName,
                factory: nil,
                factoryToken: nil,
                genericArguments: nil
            )
        }

        if let specialized = calledExpression.as(GenericSpecializationExprSyntax.self) {
            guard let reference = specialized.expression.as(DeclReferenceExprSyntax.self),
                reference.baseName.text == "Task" else { return nil }
            return TaskCall(
                anchor: reference.baseName,
                factory: nil,
                factoryToken: nil,
                genericArguments: specialized.genericArgumentClause
            )
        }

        if let member = calledExpression.as(MemberAccessExprSyntax.self) {
            guard let base = member.base?.as(DeclReferenceExprSyntax.self),
                  base.baseName.text == "Task" else { return nil }
            return TaskCall(
                anchor: base.baseName,
                factory: member.declName.baseName.text,
                factoryToken: member.declName.baseName,
                genericArguments: nil
            )
        }

        return nil
    }

    /// Whether this call creates an unstructured task.
    ///
    /// Requires a trailing closure, so `Task.isCancelled` and `Task.yield()` are excluded.
    var createsUnstructuredTask: Bool {
        guard trailingClosure != nil, let call = taskCall else { return false }
        guard let factory = call.factory else { return true }
        return Self.taskFactories.contains(factory)
    }
}
