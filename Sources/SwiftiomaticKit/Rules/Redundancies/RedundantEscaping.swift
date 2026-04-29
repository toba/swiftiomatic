import SwiftSyntax

/// Remove `@escaping` from closure parameters that demonstrably do not escape.
///
/// `@escaping` is required only when a closure parameter outlives the function call. This
/// rule uses a flow-insensitive escape check: a closure escapes if it (or a value tainted
/// by it) is returned, assigned to a non-local variable, passed to another function, or
/// referenced inside a nested closure.
///
/// The analysis is deliberately conservative — when escape can't be ruled out, the rule
/// stays silent. Protocol requirements, autoclosure-only edge cases, and parameters
/// referenced inside nested closures are all assumed to escape.
///
/// Lint: A finding is raised at the `@escaping` attribute.
///
/// Rewrite: The `@escaping` attribute is removed.
final class RedundantEscaping: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(applyRedundantEscaping(node, parent: parent, context: context))
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(applyRedundantEscaping(node, parent: parent, context: context))
    }
}
