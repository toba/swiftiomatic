import SwiftSyntax

/// Remove `@Suite` attributes that have no arguments, since they are inferred by the Swift Testing
/// framework.
///
/// `@Suite` with no arguments (or empty parentheses) is redundant — Swift Testing automatically
/// discovers test suites without explicit annotation. Only `@Suite` with arguments like
/// `@Suite(.serialized)` or `@Suite("Display Name")` should be kept.
///
/// Lint: A warning is raised when `@Suite` or `@Suite()` is used without arguments.
///
/// Rewrite: The redundant `@Suite` attribute is removed.
final class RedundantSwiftTestingSuite: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }
}
