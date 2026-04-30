import SwiftSyntax

/// Lint nested `<receiver>.withLock { ... <receiver>.withLock { ... } ... }`
/// on the same receiver. Re-entering a non-recursive lock (e.g. `Mutex`) is a
/// guaranteed deadlock.
final class NoNestedWithLock: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let outerReceiver = Self.withLockReceiver(of: node),
              let outerClosure = Self.closureArgument(of: node)
        else {
            return .visitChildren
        }

        let collector = NestedWithLockCollector(receiver: outerReceiver.trimmedDescription, viewMode: .sourceAccurate)
        collector.walk(outerClosure.statements)
        for inner in collector.matches {
            diagnose(.nestedWithLock, on: inner)
        }
        return .visitChildren
    }

    fileprivate static func withLockReceiver(of call: FunctionCallExprSyntax) -> ExprSyntax? {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "withLock"
        else {
            return nil
        }
        return member.base
    }

    fileprivate static func closureArgument(of call: FunctionCallExprSyntax) -> ClosureExprSyntax? {
        if let trailing = call.trailingClosure {
            return trailing
        }
        return call.arguments.first?.expression.as(ClosureExprSyntax.self)
    }
}

private final class NestedWithLockCollector: SyntaxVisitor {
    let receiver: String
    var matches: [FunctionCallExprSyntax] = []

    init(receiver: String, viewMode: SyntaxTreeViewMode) {
        self.receiver = receiver
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let innerReceiver = NoNestedWithLock.withLockReceiver(of: node),
           innerReceiver.trimmedDescription == receiver
        {
            matches.append(node)
        }
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let nestedWithLock: Finding.Message =
        "nested 'withLock' on the same receiver — re-entering a non-recursive lock deadlocks"
}
