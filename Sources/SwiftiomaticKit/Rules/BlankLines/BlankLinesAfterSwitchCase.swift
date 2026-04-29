import SwiftSyntax

/// Insert a blank line after multiline switch case bodies.
///
/// When a switch case body spans multiple statements, a blank line after it improves readability
/// by visually separating it from the next case. Single-statement cases do not require blank lines.
/// The last case in a switch is never followed by a blank line (the closing brace provides
/// visual separation).
///
/// Lint: If a multiline case body is not followed by a blank line, a lint warning is raised.
///       If the last case is followed by a blank line before `}`, a lint warning is raised.
///
/// Rewrite: Blank lines are inserted after multiline cases and removed after the last case.
final class BlankLinesAfterSwitchCase: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "afterSwitchCase" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
