import SwiftSyntax

/// Flag `Task { ... }` started from a `@MainActor`-isolated context. The unstructured `Task`
/// initializer inherits the isolation of the caller, so its body runs on the main actor. The cost
/// is a deferred start: the body does not run until the main actor reaches a later turn, so work
/// that the caller expects to happen now happens later. Prefer `Task.immediate` (or
/// `Task.immediate(priority:)`), which starts execution synchronously on the calling actor and only
/// suspends at the first `await` that requires it.
///
/// Detection walks enclosing parents looking for `@MainActor` on a function, computed property
/// accessor, closure, type, or extension. Matches false-positive-friendly: `Task { ... }` with any
/// priority arg form fires when the enclosing decl carries the attribute. Detached and
/// named-static-method forms (`Task.detached`, `Task.immediate`) are not flagged here.
///
/// The rule also flags `Task { ... }` as a statement in a function with the `@IBAction`
/// attribute. An `@IBAction` method runs on the main actor, and a `Task` in it defers the work of
/// the action to a later turn.
///
/// Lint: A `Task { ... }` starts in a `@MainActor` context or as a statement in an `@IBAction`.
final class FlagTaskInMainActor: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Only the bare initializer. A static factory hops off on purpose.
        guard let call = node.taskCall, call.factory == nil, call.genericArguments == nil
        else { return .visitChildren }
        guard isMainActorIsolated(node) || isStatementInIBAction(node) else {
            return .visitChildren
        }
        diagnose(.taskInMainActor, on: node.calledExpression)
        return .visitChildren
    }

    /// Walks parent decls / closures looking for an explicit `@MainActor` attribute. Stops at the
    /// first attribute-bearing node — inner `nonisolated` overrides are not modeled.
    private func isMainActorIsolated(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = node.parent

        while let parent = current {
            if let withAttrs = parent.asProtocol((any WithAttributesSyntax).self),
               withAttrs.attributes.attribute(named: "MainActor") != nil { return true }
            current = parent.parent
        }
        return false
    }

    /// Returns `true` when the call is a statement and the nearest enclosing function carries
    /// `@IBAction`.
    private func isStatementInIBAction(_ node: FunctionCallExprSyntax) -> Bool {
        guard node.parent?.is(CodeBlockItemSyntax.self) == true else { return false }
        var current: Syntax? = node.parent

        while let parent = current {
            if let function = parent.as(FunctionDeclSyntax.self) {
                return function.attributes.attribute(named: "IBAction") != nil
            }
            current = parent.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let taskInMainActor: Finding.Message =
        "'Task { ... }' on the main actor inherits the caller's isolation but defers its start to a later turn; use 'Task.immediate' to start synchronously on the calling actor"
}
