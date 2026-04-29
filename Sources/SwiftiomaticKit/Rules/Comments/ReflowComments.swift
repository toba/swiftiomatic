import SwiftSyntax

/// Reflows contiguous `///` and `//` comment runs to fit `lineLength`.
///
/// DocC structures are preserved: parameter blocks, lists, code fences, block quotes, URLs, inline
/// code spans, and Markdown links are never split mid-token. Continuation lines in `- Parameter:`
/// blocks align under the description column.
///
/// Lint: A comment block whose lines could be redistributed to fit `lineLength` raises a warning.
///
/// Rewrite: The comment block is rebuilt with reflowed prose; code fences and atomic tokens are
/// emitted verbatim.
final class ReflowComments: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .comments }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
