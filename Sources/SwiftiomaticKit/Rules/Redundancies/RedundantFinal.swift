import SwiftSyntax

/// Remove redundant `final` from members of `final` classes.
///
/// When a class is declared `final`, all its members are implicitly final.
/// Adding `final` to individual members is redundant.
///
/// Lint: If a `final` modifier is found on a member of a `final` class, a warning is raised.
///
/// Rewrite: The redundant `final` modifier is removed.
final class RedundantFinal: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }
}
