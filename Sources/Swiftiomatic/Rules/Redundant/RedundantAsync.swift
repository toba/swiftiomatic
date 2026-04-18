import SwiftSyntax

/// Remove `async` from functions that contain no `await` expressions.
///
/// If a function is marked `async` but its body never uses `await`, the `async` is likely
/// unnecessary. Removing it simplifies the API and removes the requirement for callers
/// to use `await`.
///
/// This rule is opt-in because some functions are intentionally async for protocol
/// conformance or future-proofing even if they don't currently await.
///
/// Lint: If an `async` function has no `await` in its body, a lint warning is raised.
///
/// Format: The `async` specifier is removed.
final class RedundantAsync: SyntaxFormatRule {
    static let isOptIn = true
    static let group: ConfigGroup? = .redundancies

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let effectSpecifiers = node.signature.effectSpecifiers,
            let asyncSpecifier = effectSpecifiers.asyncSpecifier,
            asyncSpecifier.tokenKind == .keyword(.async),
            let body = node.body
        else {
            return DeclSyntax(node)
        }

        guard !containsAwait(body) else {
            return DeclSyntax(node)
        }

        diagnose(.removeRedundantAsync, on: asyncSpecifier)

        var newEffectSpecifiers = effectSpecifiers
        newEffectSpecifiers.asyncSpecifier = nil

        // Transfer trivia: async's leading trivia should go to the next token.
        if let throwsClause = newEffectSpecifiers.throwsClause {
            newEffectSpecifiers.throwsClause = throwsClause.with(
                \.throwsSpecifier,
                throwsClause.throwsSpecifier.with(\.leadingTrivia, asyncSpecifier.leadingTrivia)
            )
        }

        var result = node
        // If no specifiers remain, remove the entire effectSpecifiers to avoid empty node.
        if newEffectSpecifiers.asyncSpecifier == nil && newEffectSpecifiers.throwsClause == nil {
            result.signature.effectSpecifiers = nil
        } else {
            result.signature.effectSpecifiers = newEffectSpecifiers
        }
        return DeclSyntax(result)
    }

    /// Returns `true` if the syntax tree contains an `await` expression,
    /// stopping at nested function/closure boundaries.
    private func containsAwait(_ node: some SyntaxProtocol) -> Bool {
        for child in node.children(viewMode: .sourceAccurate) {
            // Stop at nested function/closure boundaries — they have their own async context.
            if child.is(FunctionDeclSyntax.self) || child.is(ClosureExprSyntax.self) {
                continue
            }
            if child.is(AwaitExprSyntax.self) {
                return true
            }
            if containsAwait(child) {
                return true
            }
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantAsync: Finding.Message =
        "function is 'async' but contains no 'await'; consider removing 'async'"
}
