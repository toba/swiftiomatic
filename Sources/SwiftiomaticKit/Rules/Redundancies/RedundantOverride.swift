import SwiftSyntax

/// Remove `override` declarations whose body only forwards identical arguments to `super`.
///
/// An override that does nothing other than `super.<name>(...)` with the same parameters
/// (in order, with matching labels) adds no behavior.
///
/// The rule is conservative:
/// - Bails out if the override has any attributes (e.g. `@available`).
/// - Bails out if any parameter has a default value (the override may be tightening defaults).
/// - Bails out if the call uses a trailing closure or `try!`/`try?` (assumed to change behavior).
/// - Skips overrides explicitly required by tests (`tearDown`, `setUp`, etc.) and common
///   UIKit/AppKit lifecycle methods that are typically intentional anchors.
///
/// Lint: A finding is raised on the `override` keyword.
///
/// Rewrite: The entire `override` declaration is removed, preserving surrounding trivia.
final class RedundantOverride: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        applyRedundantOverride(node, parent: parent, context: context)
    }
}
