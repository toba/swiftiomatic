import SwiftSyntax

/// `NotificationCenter.default.removeObserver(self)` should only appear in `deinit`.
///
/// Removing the observer earlier (e.g. in `viewWillDisappear`) prevents notifications from being
/// delivered when the object is otherwise still alive. The correct place to detach is `deinit`,
/// which runs exactly once at the end of the object's lifetime.
///
/// Lint: A call to `NotificationCenter.default.removeObserver(self)` outside `deinit` yields a
/// warning. Removing other observers (e.g. `removeObserver(otherObject)`) is allowed anywhere.
final class DeinitObserverRemoval: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {

    /// Skip the body of `deinit` entirely — removal of `self` as observer is the recommended
    /// pattern there.
    override func visit(_: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.isNotificationCenterRemoveObserverCall,
            node.trailingClosure == nil,
            node.arguments.count == 1,
            let arg = node.arguments.first,
            arg.label == nil,
            let ref = arg.expression.as(DeclReferenceExprSyntax.self),
            ref.baseName.tokenKind == .keyword(.self)
        else {
            return .visitChildren
        }

        diagnose(.deinitObserverRemoval, on: node)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let deinitObserverRemoval: Finding.Message =
        "remove 'self' as a notification observer only in 'deinit'"
}

extension FunctionCallExprSyntax {
    /// True if the called expression is `NotificationCenter.default.removeObserver`.
    fileprivate var isNotificationCenterRemoveObserverCall: Bool {
        guard let outer = calledExpression.as(MemberAccessExprSyntax.self),
            outer.declName.baseName.text == "removeObserver",
            let inner = outer.base?.as(MemberAccessExprSyntax.self),
            inner.declName.baseName.text == "default",
            let root = inner.base?.as(DeclReferenceExprSyntax.self),
            root.baseName.text == "NotificationCenter"
        else {
            return false
        }
        return true
    }
}
