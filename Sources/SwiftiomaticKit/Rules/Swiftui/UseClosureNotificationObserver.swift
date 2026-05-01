import SwiftSyntax

/// Lint selector-based `NotificationCenter.addObserver(_:selector:name:object:)` . Prefer the
/// closure-based `addObserver(forName:object:queue:using:)` — it returns an opaque token, doesn't
/// require an `@objc` handler, and integrates cleanly with structured concurrency.
final class UseClosureNotificationObserver: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "addObserver" else { return .visitChildren }
        let labels = node.arguments.map { $0.label?.text }
        // selector form: (_, selector:, name:, object:)
        guard labels.count == 4,
              labels[0] == nil,
              labels[1] == "selector",
              labels[2] == "name",
              labels[3] == "object" else { return .visitChildren }
        diagnose(.preferClosureObserver, on: node)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let preferClosureObserver: Finding.Message =
        "selector-based 'addObserver' requires '@objc' and manual cleanup — prefer closure-based 'addObserver(forName:object:queue:using:)' or 'NotificationCenter.Message'"
}
