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

    /// Tracks whether the *immediately* enclosing closure is multi-line. Single-line closures
    /// inside a multi-line outer closure are still fine (`$0` only refers to the inner closure's
    /// parameters).
    private var insideMultilineClosure = false

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        let converter = context.sourceLocationConverter
        let startLine = converter.location(
            for: node.leftBrace.positionAfterSkippingLeadingTrivia
        ).line
        let endLine = converter.location(
            for: node.rightBrace.endPositionBeforeTrailingTrivia
        ).line

        let saved = insideMultilineClosure
        insideMultilineClosure = (startLine != endLine)
        defer { insideMultilineClosure = saved }
        return super.visit(node)
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        if insideMultilineClosure,
            case .dollarIdentifier = node.baseName.tokenKind
        {
            diagnose(.preferNamedClosureParam(name: node.baseName.text), on: node.baseName)
        }
        return super.visit(node)
    }

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
