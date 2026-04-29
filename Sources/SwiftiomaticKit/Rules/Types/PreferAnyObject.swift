import SwiftSyntax

/// Prefer `AnyObject` over `class` for class-constrained protocols.
///
/// The `class` keyword in protocol inheritance clauses was replaced by `AnyObject` in Swift 4.1.
/// Using `AnyObject` is the modern, preferred spelling.
///
/// Lint: A protocol inheriting from `class` instead of `AnyObject` raises a warning.
///
/// Rewrite: `class` is replaced with `AnyObject` in the inheritance clause.
final class PreferAnyObject: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .types }
}
