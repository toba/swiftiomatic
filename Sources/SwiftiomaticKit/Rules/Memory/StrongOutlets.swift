import SwiftSyntax

/// Remove `weak` from `@IBOutlet` properties.
///
/// As per Apple's recommendation, `@IBOutlet` properties should be strong. The `weak`
/// modifier is preserved for delegate and data source outlets since those are typically
/// owned elsewhere.
///
/// Lint: An `@IBOutlet` property with `weak` raises a warning.
///
/// Rewrite: The `weak` modifier is removed.
final class StrongOutlets: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }
}
