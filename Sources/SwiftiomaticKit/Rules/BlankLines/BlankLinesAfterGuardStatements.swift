import SwiftSyntax

/// Remove blank lines between consecutive guard statements and insert a blank line after
/// the last guard.
///
/// Guard blocks at the top of a function form a precondition section. Keeping them tight
/// (no blank lines between them) and separated from the body (one blank line after) improves
/// readability. Comments between guards break the "consecutive" chain — each guard followed
/// by a comment gets its own trailing blank line.
///
/// Lint: If there are blank lines between consecutive guards, or no blank line after the
///       last guard before other code, a lint warning is raised.
///
/// Rewrite: Blank lines between consecutive guards are removed. A blank line is inserted
///         after the last guard when followed by non-guard code.
final class BlankLinesAfterGuardStatements: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "afterGuardStatements" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
