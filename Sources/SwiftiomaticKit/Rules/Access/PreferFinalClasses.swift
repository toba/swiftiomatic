import SwiftSyntax

/// Prefer `final class` unless a class is designed for subclassing.
///
/// Classes should be `final` by default to communicate that they are not designed to be subclassed.
/// Classes are left non-final if they are `open`, have "Base" in the name, have a comment
/// mentioning "base" or "subclass", or are subclassed within the same file.
///
/// When a class is made `final`, any `open` members are converted to `public` since `final`
/// classes cannot have `open` members.
///
/// Lint: A non-final, non-open class declaration raises a warning.
///
/// Rewrite: The `final` modifier is added and `open` members are converted to `public`.
final class PreferFinalClasses: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        preferFinalClassesCollect(node, context: context)
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(applyPreferFinalClasses(node, context: context))
    }
}
