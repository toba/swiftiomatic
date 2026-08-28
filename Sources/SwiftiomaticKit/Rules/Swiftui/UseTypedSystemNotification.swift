import SwiftSyntax

/// Flag uses of system notifications whose name has a typed `NotificationCenter.MainActorMessage`
/// adapter on macOS 26 / iOS 26+. Matches `addObserver(forName:...)`, `.notifications(named:)`,
/// `.messages(named:)`, and `post(name:...)` whose name argument matches an entry in
/// `NotificationAPI.generatedSystemAdapters` (SDK-derived) or
/// `NotificationAPI.foundationLegacyAdapters` (free-floating Foundation names).
///
/// Flag-only — the suggested replacement (`addObserver(of:for:)` / `messages(of:)`) reshapes the
/// surrounding call and is out of scope for an autofix.
final class UseTypedSystemNotification: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        for arg in node.arguments {
            guard let label = arg.label?.text,
                  NotificationAPI.nameArgumentLabels.contains(label),
                  let replacement = NotificationAPI.adapter(for: arg.expression) else { continue }
            let displayName = NotificationAPI.qualifiedNotificationName(arg.expression)
                ?? arg.expression.trimmedDescription
            diagnose(.adapted(name: displayName, replacement: replacement), on: arg.expression)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func adapted(name: String, replacement: String) -> Finding.Message {
        "'\(name)' has a typed adapter '\(replacement)' on OS 26+ — prefer 'addObserver(of:for:)' / 'messages(of:)' with the typed message"
    }
}
