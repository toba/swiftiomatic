import SwiftSyntax

/// Ensure the file ends with exactly one newline.
///
/// Many Unix tools expect files to end with a newline. Missing trailing newlines cause `diff` noise
/// and `cat` concatenation issues. Extra trailing newlines waste space.
///
/// Lint: If the file does not end with exactly one newline, a lint warning is raised.
///
/// Rewrite: A trailing newline is added if missing, or extra newlines are removed.
final class EnsureLineBreakAtEOF: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var key: String { "atEndOfFile" }
    override class var group: ConfigurationGroup? { .lineBreaks }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
