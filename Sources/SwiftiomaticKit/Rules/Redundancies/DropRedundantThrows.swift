import SwiftSyntax

/// Remove `throws` from functions that contain no `throw` or `try` expressions.
///
/// If a function is marked `throws` but its body never uses `throw` or `try` , the `throws` is
/// likely unnecessary.
///
/// Some functions are intentionally throwing for protocol conformance or future-proofing even if
/// they don't currently throw.
///
/// Lint: If a `throws` function has no `throw` or `try` in its body, a lint warning is raised.
///
/// Rewrite: The `throws` clause is removed.
final class DropRedundantThrows: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 860

    override class var group: ConfigurationGroup? { .redundancies }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let effectSpecifiers = node.signature.effectSpecifiers,
              let throwsClause = effectSpecifiers.throwsClause,
              let body = node.body else { return DeclSyntax(node) }

        // Without type info we can't see whether this function overrides a throwing requirement or
        // whether external callers wrap it in `try`. Restrict the rewrite to functions that syntax
        // alone proves are local: not `override`, and explicitly `private`/`fileprivate`.
        guard !node.modifiers.contains(.override),
              node.modifiers.contains(anyOf: [.private, .fileprivate])
        else { return DeclSyntax(node) }

        guard !containsThrowOrTry(body) else { return DeclSyntax(node) }

        Self.diagnose(.removeRedundantThrows, on: throwsClause, context: context)

        var newEffectSpecifiers = effectSpecifiers
        newEffectSpecifiers.throwsClause = nil

        var result = node

        result.signature.effectSpecifiers = newEffectSpecifiers.asyncSpecifier == nil
            ? nil
            : newEffectSpecifiers
        return DeclSyntax(result)
    }

    /// Returns `true` if the syntax tree contains a `throw` statement, a `try` expression or a
    /// `for try await` loop, stopping at nested function/closure boundaries.
    private static func containsThrowOrTry(_ node: some SyntaxProtocol) -> Bool {
        for child in node.children(viewMode: .sourceAccurate) {
            if child.is(FunctionDeclSyntax.self) || child.is(ClosureExprSyntax.self) { continue }
            if child.is(ThrowStmtSyntax.self) || child.is(TryExprSyntax.self) { return true }
            // for try await carries the try as a bare token, never as a try expression
            if let forStmt = child.as(ForStmtSyntax.self), forStmt.tryKeyword != nil { return true }
            if containsThrowOrTry(child) { return true }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantThrows: Finding.Message =
        "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"
}
