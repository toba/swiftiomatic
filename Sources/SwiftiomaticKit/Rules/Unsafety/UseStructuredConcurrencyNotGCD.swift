import SwiftSyntax

/// Flag Grand Central Dispatch and `OperationQueue` where structured concurrency fits.
///
/// A dispatch queue carries no isolation the compiler can check, no cancellation, and no return
/// channel. A task, a task group and an actor carry all three, and the compiler enforces the data
/// isolation that a queue only documents in a comment.
///
/// The rule matches the type name wherever it appears, so it also reports a stored queue, a queue
/// parameter and a queue in a generic argument. It stays quiet on a file that names none of the
/// three types.
///
/// Lint: A reference to `DispatchQueue` , `DispatchGroup` or `OperationQueue` raises a warning.
final class UseStructuredConcurrencyNotGCD: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        flag(node.name)
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        flag(node.baseName)
        return .visitChildren
    }

    private func flag(_ token: TokenSyntax) {
        switch token.text {
            case "DispatchQueue": diagnose(.dispatchQueue, on: token)
            case "DispatchGroup": diagnose(.dispatchGroup, on: token)
            case "OperationQueue": diagnose(.operationQueue, on: token)
            default: break
        }
    }
}

fileprivate extension Finding.Message {
    static let dispatchQueue: Finding.Message =
        "'DispatchQueue' carries no isolation the compiler can check — use a task, a task group, or an actor"
    static let dispatchGroup: Finding.Message =
        "'DispatchGroup' waits without cancellation — use a task group, which awaits its children"
    static let operationQueue: Finding.Message =
        "'OperationQueue' predates structured concurrency — use a task group, or an actor for serialized state"
}
