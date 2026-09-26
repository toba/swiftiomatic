import SwiftSyntax

/// Pass an explicit `priority:` when starting an unstructured task.
///
/// `Task { }` inherits the priority of its caller, and `Task.detached { }` runs at the default
/// priority. Neither default states how urgent the work is. An explicit priority lets the scheduler
/// run user-facing work first and background work last.
///
/// `Task { }` and `Task.immediate { }` stay silent in a main-actor UI context, because that work
/// correctly inherits the priority of the UI event that started it. The rule treats these as a
/// main-actor UI context:
///
/// - a closure that declares `@MainActor`,
/// - a declaration that carries `@MainActor`, and everything inside it,
/// - a SwiftUI type (`View`, `ViewModifier`, `App`, `Scene`) or an AppKit or UIKit representable.
///
/// `Task.detached { }` and `Task.immediateDetached { }` always fire. A detached task inherits no
/// priority, so the exemption does not apply.
///
/// Lint: An unstructured task with no `priority:` argument outside a main-actor UI context raises a
/// warning.
final class RequireTaskPriority: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }
    override class var guidance: GuidanceLevel { .consider }

    /// The types whose members run on the main actor to service UI events.
    private static let uiTypes: Set<String> = [
        "View", "ViewModifier", "App", "Scene",
        "NSViewRepresentable", "UIViewRepresentable",
        "NSViewControllerRepresentable", "UIViewControllerRepresentable",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.createsUnstructuredTask, let call = node.taskCall else { return .visitChildren }
        guard !node.arguments.contains(where: { $0.label?.text == "priority" }) else {
            return .visitChildren
        }

        let detached = call.factory == "detached" || call.factory == "immediateDetached"

        if !detached, isMainActorClosure(node.trailingClosure) || isInMainActorUIContext(node) {
            return .visitChildren
        }

        if let factory = call.factory, let token = call.factoryToken {
            diagnose(.taskStaticMissingPriority(factory), on: token)
        } else {
            diagnose(.taskInitMissingPriority, on: call.anchor)
        }
        return .visitChildren
    }

    private func isMainActorClosure(_ closure: ClosureExprSyntax?) -> Bool {
        closure?.signature?.attributes.attribute(named: "MainActor") != nil
    }

    /// Reports whether an enclosing declaration carries `@MainActor` or is a UI type.
    private func isInMainActorUIContext(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let syntax = current {
            if let decl = syntax.asProtocol(WithAttributesSyntax.self),
               decl.attributes.attribute(named: "MainActor") != nil { return true }

            if let group = syntax.asProtocol(DeclGroupSyntax.self),
               let inheritance = group.inheritanceClause,
               Self.uiTypes.contains(where: inheritance.contains(named:)) { return true }
            current = syntax.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let taskInitMissingPriority: Finding.Message =
        "'Task { ... }' has no priority; pass 'priority:' to state how urgent the work is"
    static func taskStaticMissingPriority(_ name: String) -> Finding.Message {
        "'Task.\(name)' has no priority; pass 'priority:' to state how urgent the work is"
    }
}
