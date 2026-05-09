import SwiftSyntax

/// Flag `Task { ... }` started from a `@MainActor`-isolated context. The unstructured `Task`
/// initializer hops off the main actor unless the body's first awaited work is itself
/// main-actor-isolated, defeating the caller's isolation guarantee. Prefer `Task.immediate`
/// (or `Task.immediate(priority:)`), which starts execution synchronously on the calling
/// actor and only suspends at the first `await` that requires it.
///
/// Detection walks enclosing parents looking for `@MainActor` on a function, computed
/// property accessor, closure, type, or extension. Matches false-positive-friendly:
/// `Task { ... }` with any priority arg form fires when the enclosing decl carries the
/// attribute. Detached and named-static-method forms (`Task.detached`, `Task.immediate`)
/// are not flagged here.
///
/// Caveat noted in the message: a `Task` body whose first work suspends off-main is the
/// silent-fallback case the rule is named for — the runtime drops main-actor isolation
/// without a diagnostic, so reviewing flagged sites is worthwhile even when the body
/// "looks fine."
final class FlagTaskInMainActor: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "Task" else { return .visitChildren }
        guard isMainActorIsolated(node) else { return .visitChildren }
        diagnose(.taskInMainActor, on: node.calledExpression)
        return .visitChildren
    }

    /// Walks parent decls / closures looking for an explicit `@MainActor` attribute. Stops at
    /// the first attribute-bearing node — inner `nonisolated` overrides are not modeled.
    private func isMainActorIsolated(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = node.parent
        while let parent = current {
            if let withAttrs = parent.asProtocol(WithAttributesSyntax.self),
               withAttrs.attributes.attribute(named: "MainActor") != nil
            {
                return true
            }
            current = parent.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let taskInMainActor: Finding.Message =
        "'Task { ... }' from a '@MainActor' context hops off the main actor unless the body's first work is main-actor-isolated — use 'Task.immediate' to start synchronously on the calling actor"
}
