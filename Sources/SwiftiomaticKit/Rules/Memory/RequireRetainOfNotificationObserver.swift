import SwiftSyntax

/// `NotificationCenter.addObserver(forName:object:queue:using:)` returns an opaque token that must
/// be retained to later remove the observer. Discarding the return value leaks the observer.
///
/// Lint: When a call to `addObserver(forName:object:queue:...)` is used as a statement (not stored,
/// returned, or passed to another call), a warning is raised.
final class RequireRetainOfNotificationObserver: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }
    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard isAddObserverCall(node) else { return .visitChildren }
        guard !isResultConsumed(node) else { return .visitChildren }
        diagnose(.discardedObserver, on: node)
        return .visitChildren
    }

    /// True if `node` is a call of the form `<expr>.addObserver(forName:object:queue:...)` .
    private func isAddObserverCall(_ node: FunctionCallExprSyntax) -> Bool {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "addObserver" else { return false }
        let labels = node.arguments.map { $0.label?.text }
        return labels.starts(with: ["forName", "object", "queue"])
    }

    /// Returns true if the call's value is captured by an enclosing expression: assigned, returned,
    /// used as a function argument, or included in an array/dictionary literal.
    private func isResultConsumed(_ node: FunctionCallExprSyntax) -> Bool {
        guard let parent = node.parent else { return false }

        // `let x = ...` or default value position
        if parent.is(InitializerClauseSyntax.self) { return true }

        // `return ...` — but if the enclosing function is `@discardableResult` , the caller may
        // still drop the observer.
        if parent.is(ReturnStmtSyntax.self) { return !enclosingFunctionIsDiscardable(node) }

        // Function argument: `obs.append(<call>)`
        if parent.is(LabeledExprSyntax.self) { return true }

        // Array literal element
        if parent.is(ArrayElementSyntax.self) { return true }

        // Dictionary literal value
        if parent.is(DictionaryElementSyntax.self) { return true }

        // Member access on the result, e.g. `<call>.token`
        if parent.is(MemberAccessExprSyntax.self) { return true }

        // Subscript usage: `dict[key] = <call>` puts the call in an ExprListSyntax with an
        // AssignmentExpr.
        if let list = parent.as(ExprListSyntax.self),
           list.contains(where: { $0.is(AssignmentExprSyntax.self) })
        {
            return true
        }

        // `_ = nc.addObserver(...)` is intentionally an unsuppressed warning. Other parents
        // (CodeBlockItem) are statement positions: result is discarded.
        return false
    }

    /// Walks up `node` 's parent chain to find the immediately enclosing `FunctionDeclSyntax`
    /// (stopping at closures so we don't cross boundaries) and returns true if it's marked
    /// `@discardableResult` .
    private func enclosingFunctionIsDiscardable(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = Syntax(node)

        while let curr = current {
            if curr.is(ClosureExprSyntax.self) { return false }

            if let funcDecl = curr.as(FunctionDeclSyntax.self) {
                return funcDecl.attributes.contains(where: { element in
                    guard let attribute = element.as(AttributeSyntax.self) else { return false }
                    return attribute.attributeName.trimmedDescription == "discardableResult"
                })
            }
            current = curr.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let discardedObserver: Finding.Message =
        "store the observer returned by addObserver(forName:object:queue:) so it can be removed later"
}
