import SwiftSyntax

/// Flag a hand-rolled lock type.
///
/// A lock protects state the compiler cannot see, so nothing checks that every access takes the
/// lock. An actor moves the same state behind isolation the compiler enforces. When the critical
/// section is synchronous and an actor would force the callers to become `async` , `Mutex` from the
/// Synchronization module holds the state and the compiler still checks the access.
///
/// The rule matches the type name wherever it appears, in a type annotation as much as in a call.
///
/// Lint: A reference to `NSLock` , `NSRecursiveLock` , `NSConditionLock` , `os_unfair_lock` or
/// `pthread_mutex_t` raises a warning.
final class UseActorNotLock: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private static let lockTypes: Set<String> = [
        "NSConditionLock",
        "NSLock",
        "NSRecursiveLock",
        "os_unfair_lock",
        "os_unfair_lock_t",
        "pthread_mutex_t",
    ]

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        flag(node.name)
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        flag(node.baseName)
        return .visitChildren
    }

    private func flag(_ token: TokenSyntax) {
        guard Self.lockTypes.contains(token.text) else { return }
        diagnose(.useActorNotLock(token.text), on: token)
    }
}

fileprivate extension Finding.Message {
    static func useActorNotLock(_ name: String) -> Finding.Message {
        """
        '\(name)' guards state the compiler cannot see — use an actor, or 'Mutex' from \
        Synchronization when the critical section is synchronous
        """
    }
}
