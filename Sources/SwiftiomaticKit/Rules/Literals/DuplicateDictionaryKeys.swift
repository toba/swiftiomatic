import SwiftSyntax

/// Dictionary literals with duplicate keys silently overwrite earlier values.
///
/// The Swift compiler accepts duplicate static keys but the resulting dictionary only retains the
/// *last* value for each key — almost always a copy-paste bug.
///
/// Only static keys are checked: literals, identifiers, and member access expressions. Dynamic keys
/// like `UUID()` or `#line` can legitimately produce distinct values at runtime and are skipped.
///
/// Lint: When a static key appears more than once in the same dictionary literal, every occurrence
/// after the first is flagged.
final class DuplicateDictionaryKeys: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }

    override func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
        var seen: [String: DictionaryElementSyntax] = [:]

        for element in node {
            guard let key = staticKey(of: element.key) else { continue }

            if seen[key] != nil {
                diagnose(.duplicateKey(key), on: element.key)
            } else {
                seen[key] = element
            }
        }
        return .visitChildren
    }

    /// Returns a normalized string for a key expression that can be statically compared, or `nil`
    /// if the key is dynamic.
    private func staticKey(of expr: ExprSyntax) -> String? {
        expr.is(StringLiteralExprSyntax.self)
            || expr.is(IntegerLiteralExprSyntax.self)
            || expr.is(FloatLiteralExprSyntax.self)
            || expr.is(BooleanLiteralExprSyntax.self)
            || expr.is(NilLiteralExprSyntax.self)
            || expr.is(MemberAccessExprSyntax.self)
            || expr.is(DeclReferenceExprSyntax.self)
            ? expr.trimmedDescription
            : nil
    }
}

fileprivate extension Finding.Message {
    static func duplicateKey(_ key: String) -> Finding.Message {
        "duplicate key '\(key)' in dictionary literal — last value wins"
    }
}
