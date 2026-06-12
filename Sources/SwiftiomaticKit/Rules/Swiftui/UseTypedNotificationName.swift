import SwiftSyntax

/// Flag custom `Notification.Name` declarations — `extension Notification.Name { static let foo = ... }`
/// and `Notification.Name("...")` / `Notification.Name(rawValue: "...")` literal constructions. On
/// macOS 26 / iOS 26+, prefer a `NotificationCenter.MainActorMessage` (or `AsyncMessage`) struct
/// for type- and isolation-safety.
///
/// Flag-only — autofix is out of scope (the producer-side `post` call carries the `userInfo` shape
/// needed to synthesize the message struct).
final class UseTypedNotificationName: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if NotificationAPI.isNotificationNameType(node.extendedType) {
            diagnose(.customNotificationName, on: node.extendedType)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Match `Notification.Name("...")` or `Notification.Name(rawValue: "...")`.
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "Name",
              let base = member.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.text == "Notification" else { return .visitChildren }
        diagnose(.customNotificationName, on: node)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let customNotificationName: Finding.Message =
        "custom 'Notification.Name' is pre-OS 26 — prefer a 'NotificationCenter.MainActorMessage' (or 'AsyncMessage') struct for type- and isolation-safety"
}
