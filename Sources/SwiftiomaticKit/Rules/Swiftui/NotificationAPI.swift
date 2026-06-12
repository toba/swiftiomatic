import SwiftSyntax

/// Shared helpers for NotificationCenter-modernization lint rules on OS 26+
/// (`UseClosureNotificationObserver`, `UseTypedNotificationName`,
/// `UseTypedSystemNotification`).
enum NotificationAPI {
    /// Foundation legacy *free-floating* notification names whose typed
    /// `NotificationCenter.MainActorMessage` adapter ships on OS 26+. These don't appear in
    /// swiftinterfaces (the swiftinterface only contains the `Message` struct, not the legacy
    /// name constant), so the table is hand-maintained from
    /// `~/Developer/swiftiomatic/.issues/9/95w-eow…`.
    static let foundationLegacyAdapters: [String: String] = [
        "NSCalendarDayChanged": "Date.SystemClockDidChangeMessage",
        "NSSystemClockDidChange": "Date.SystemClockDidChangeMessage",
        "NSSystemTimeZoneDidChange": "TimeZone.SystemTimeZoneDidChangeMessage",
        "NSCurrentLocaleDidChange": "Locale.CurrentLocaleDidChangeMessage",
        "NSUbiquityIdentityDidChange": "FileManager.UbiquityIdentityDidChangeMessage",
        "NSExtensionHostDidBecomeActive": "NSExtensionContext.DidBecomeActiveMessage",
        "NSExtensionHostDidEnterBackground": "NSExtensionContext.DidEnterBackgroundMessage",
        "NSExtensionHostWillEnterForeground": "NSExtensionContext.WillEnterForegroundMessage",
        "NSExtensionHostWillResignActive": "NSExtensionContext.WillResignActiveMessage",
        "NSUndoManagerCheckpoint": "UndoManager.CheckpointMessage",
        "NSUndoManagerDidOpenUndoGroup": "UndoManager.DidOpenUndoGroupMessage",
        "NSUndoManagerDidCloseUndoGroup": "UndoManager.DidCloseUndoGroupMessage",
        "NSUndoManagerWillCloseUndoGroup": "UndoManager.WillCloseUndoGroupMessage",
        "NSUndoManagerDidUndoChange": "UndoManager.DidUndoChangeMessage",
        "NSUndoManagerDidRedoChange": "UndoManager.DidRedoChangeMessage",
        "NSUndoManagerWillUndoChange": "UndoManager.WillUndoChangeMessage",
        "NSUndoManagerWillRedoChange": "UndoManager.WillRedoChangeMessage",
    ]

    /// Argument labels that carry a `Notification.Name` value in the legacy NotificationCenter
    /// API. Used to locate the relevant argument inside a call expression.
    static let nameArgumentLabels: Set<String> = ["forName", "name", "named"]

    /// Look up the typed `MainActorMessage` adapter for a syntactic notification-name
    /// expression. Handles two forms:
    ///   - `Type.memberNotification` (member access) — matches against the generated
    ///     SDK-derived table.
    ///   - bare identifier `NSFooDidBarNotification` (free-floating Foundation names) — matches
    ///     against the hand-maintained legacy table.
    /// Returns the qualified replacement type, e.g. `"UndoManager.DidCloseUndoGroupMessage"`.
    static func adapter(for expr: ExprSyntax) -> String? {
        if let qualified = qualifiedNotificationName(expr),
           let replacement = generatedSystemAdapters[qualified] {
            return replacement
        }
        if let ident = expr.as(DeclReferenceExprSyntax.self),
           let replacement = foundationLegacyAdapters[ident.baseName.text] {
            return replacement
        }
        return nil
    }

    /// If `expr` is a member-access of the form `Type.memberNotification`, returns
    /// `"Type.memberNotification"`. Returns `nil` for nested chains or shorthand `.foo`.
    static func qualifiedNotificationName(_ expr: ExprSyntax) -> String? {
        guard let member = expr.as(MemberAccessExprSyntax.self),
              let base = member.base?.as(DeclReferenceExprSyntax.self) else { return nil }
        return "\(base.baseName.text).\(member.declName.baseName.text)"
    }

    /// Whether `type` syntactically refers to `Notification.Name`.
    static func isNotificationNameType(_ type: TypeSyntax) -> Bool {
        if let member = type.as(MemberTypeSyntax.self),
           member.name.text == "Name",
           let base = member.baseType.as(IdentifierTypeSyntax.self),
           base.name.text == "Notification" {
            return true
        }
        return false
    }
}
