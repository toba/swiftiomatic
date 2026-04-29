import SwiftSyntax

/// Use named arguments in multi-line closures.
///
/// Inside a single-line closure, `$0`/`$1` is concise and idiomatic. Inside a multi-line closure
/// the anonymous form forces readers to track which argument is which by counting; an explicit
/// `arg in` parameter list reads more clearly.
///
/// Lint: A warning is raised for each `$0`/`$1`/... reference inside a multi-line closure.
///
/// Rewrite: Not auto-fixed; the rule cannot pick a meaningful parameter name.
final class NamedClosureParams: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: ClosureExprSyntax, context: Context) {
        namedClosureParamsPushClosure(node, context: context)
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        namedClosureParamsPopClosure(context: context)
    }
}

extension Finding.Message {
    fileprivate static func preferNamedClosureParam(name: String) -> Finding.Message {
        "use a named parameter instead of '\(name)' in this multi-line closure"
    }
}
