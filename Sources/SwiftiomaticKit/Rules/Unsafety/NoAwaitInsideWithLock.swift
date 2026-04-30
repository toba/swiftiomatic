import SwiftSyntax

/// Lint `withLock { ... await ... }` — holding a lock across suspension is a
/// blocking/deadlock hazard.
///
/// The rule fires on any function call whose callee is `<receiver>.withLock`
/// when the trailing closure (or first closure argument) contains an `await`
/// expression at any nesting level *outside* of nested closures (a nested
/// `Task { }` body is a separate isolation context and doesn't hold the lock).
final class NoAwaitInsideWithLock: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "withLock"
        else {
            return .visitChildren
        }

        let closure: ClosureExprSyntax?
        if let trailing = node.trailingClosure {
            closure = trailing
        } else if let first = node.arguments.first?.expression.as(ClosureExprSyntax.self) {
            closure = first
        } else {
            closure = nil
        }
        guard let closure else { return .visitChildren }

        let collector = AwaitCollector(viewMode: .sourceAccurate)
        collector.walk(closure.statements)
        if let firstAwait = collector.firstAwait {
            diagnose(.awaitInsideWithLock, on: firstAwait)
        }
        return .visitChildren
    }
}

private final class AwaitCollector: SyntaxVisitor {
    var firstAwait: AwaitExprSyntax?

    override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
        if firstAwait == nil { firstAwait = node }
        return .skipChildren
    }

    // Don't descend into nested closures — those run in a separate isolation
    // context and don't hold the outer lock.
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}

extension Finding.Message {
    fileprivate static let awaitInsideWithLock: Finding.Message =
        "'await' inside 'withLock' holds the lock across suspension — deadlock/blocking risk"
}
