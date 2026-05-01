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
    override class var group: ConfigurationGroup? { .unsafety }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }
}

extension Finding.Message {
    static func doNotForceCast(name: String) -> Finding.Message { "do not force cast to '\(name)'" }
}
