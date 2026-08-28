import SwiftSyntax

/// Force casts ( `as!` ) are forbidden.
///
/// A force cast crashes at runtime if the conversion fails. Prefer the conditional cast ( `as?` )
/// combined with optional handling ( `if let` , `guard let` , nil-coalescing, etc.).
///
/// This rule complements `NoForceTry` and `NoForceUnwrap` .
///
/// Lint: A warning is raised for each `as!` .
///
/// Rewrite: Not auto-fixed; the safe replacement depends on caller intent.
final class NoForceCast: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 240

    override class var group: ConfigurationGroup? { .unsafety }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    /// Report an `as!` force cast. The node is returned unchanged, because the safe replacement
    /// depends on caller intent.
    static func transform(
        _ node: AsExprSyntax,
        original _: AsExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AsExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else { return node }
        Self.diagnose(
            .doNotForceCast(name: node.type.trimmedDescription),
            on: node.asKeyword, context: context
        )
        return node
    }
}

extension Finding.Message {
    static func doNotForceCast(name: String) -> Finding.Message { "do not force cast to '\(name)'" }
}
