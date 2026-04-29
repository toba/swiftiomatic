import SwiftSyntax

/// Ensure consistent blank-line spacing among all cases in a switch statement.
///
/// When some cases in a switch are separated by blank lines and others aren't, the
/// inconsistency looks sloppy. This rule normalizes to whichever style is used by
/// the majority of cases: if more cases have blank lines, missing ones are added;
/// if fewer do, extra ones are removed. The last case is excluded (it's always
/// followed by `}`).
///
/// Lint: If any case's spacing is inconsistent with the majority, a lint warning is raised.
///
/// Rewrite: Blank lines are added or removed to make spacing consistent.
final class ConsistentSwitchCaseSpacing: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
