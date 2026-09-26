import SwiftSyntax

/// Keep the caught error when a `catch` clause throws a different error.
///
/// A `catch` that throws a new error without the one it caught removes the original cause. A caller
/// then sees only the new error and cannot find out which operation failed or why. Store the caught
/// error in the new error, for example as an associated value, or log it before the throw.
///
/// The rule applies only when the `catch` has a value to keep: the implicit `error` constant, or a
/// name that a catch pattern binds. A `catch` that matches a specific case or uses `is` binds no
/// value, so the rule stays silent there. A `throw` inside a closure, a nested function or a nested
/// `do` statement belongs to that inner scope, so the rule does not report it.
///
/// Lint: A `throw` in a `catch` body that never reads the caught error raises a warning.
final class NoDroppedCaughtError: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        let names = boundNames(node.catchItems)
        guard !names.isEmpty, !node.body.referencesLocal(named: names)
        else { return .visitChildren }

        let collector = ThrowCollector(viewMode: .sourceAccurate)
        collector.walk(node.body.statements)

        for throwStmt in collector.throwStatements {
            diagnose(.noDroppedCaughtError, on: throwStmt.throwKeyword)
        }
        return .visitChildren
    }

    /// Returns the names under which the `catch` body can read the caught error.
    private func boundNames(_ items: CatchItemListSyntax) -> Set<String> {
        guard !items.isEmpty else { return ["error"] }
        var names = Set<String>()

        for pattern in items.compactMap(\.pattern) {
            for token in pattern.tokens(viewMode: .sourceAccurate)
                where token.parent?.is(IdentifierPatternSyntax.self) == true
            {
                names.insert(token.text)
            }
        }
        return names
    }
}

/// Collects the `throw` statements of one `catch` body, without those of nested scopes.
private final class ThrowCollector: SyntaxVisitor {
    var throwStatements: [ThrowStmtSyntax] = []

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        throwStatements.append(node)
        return .skipChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: DoStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension Finding.Message {
    static let noDroppedCaughtError: Finding.Message =
        "keep the caught error in the error this 'catch' throws; store it in the new error or log it"
}
