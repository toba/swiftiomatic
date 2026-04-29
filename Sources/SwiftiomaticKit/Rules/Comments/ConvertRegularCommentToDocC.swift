import SwiftSyntax

/// Use doc comments for API declarations, otherwise use regular comments.
///
/// Comments immediately before type declarations, properties, methods, and other
/// API-level constructs use `///` doc comment syntax. Comments inside function
/// bodies use `//` regular comment syntax, except for nested function declarations.
///
/// Lint: When a regular comment should be a doc comment, or vice versa.
///
/// Rewrite: The comment style is corrected.
final class ConvertRegularCommentToDocC: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .comments }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ node: MemberBlockItemSyntax,
        parent _: Syntax?,
        context: Context
    ) -> MemberBlockItemSyntax {
        applyConvertRegularCommentToDocC(node, context: context)
    }

    static func transform(
        _ node: CodeBlockItemSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemSyntax {
        applyConvertRegularCommentToDocC(node, context: context)
    }
}
