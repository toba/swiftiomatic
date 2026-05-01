import SwiftSyntax

/// Use named arguments in multi-line closures.
///
/// Inside a single-line closure, `$0` / `$1` is concise and idiomatic. Inside a multi-line closure
/// the anonymous form forces readers to track which argument is which by counting; an explicit
/// `arg in` parameter list reads more clearly.
///
/// Lint: A warning is raised for each `$0` / `$1` /... reference inside a multi-line closure.
///
/// Rewrite: Not auto-fixed; the rule cannot pick a meaningful parameter name.
final class NamedClosureParams: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        /// Stack of `insideMultilineClosure` flags — one entry per nested `ClosureExprSyntax` . The
        /// top of the stack is the innermost closure; when the stack is empty, we're not inside a
        /// closure at all.
        var stack: [Bool] = []

        /// Convenience: whether the innermost enclosing closure is multi-line.
        var insideMultilineClosure: Bool { stack.last ?? false }
    }

    static func state(_ context: Context) -> State { context.namedClosureParamsState }

    // MARK: - Compact-pipeline scope hooks

    /// Push the multi-line flag for `node` onto the state stack.
    static func willEnter(_ node: ClosureExprSyntax, context: Context) {
        let converter = context.sourceLocationConverter
        let startLine = converter
            .location(
                for: node.leftBrace.positionAfterSkippingLeadingTrivia
            ).line
        let endLine = converter
            .location(
                for: node.rightBrace.endPositionBeforeTrailingTrivia
            ).line
        state(context).stack.append(startLine != endLine)
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        let s = state(context)
        if !s.stack.isEmpty { s.stack.removeLast() }
    }

    /// Diagnose `$N` references at the current closure scope.
    static func rewriteDeclReference(_ node: DeclReferenceExprSyntax, context: Context) {
        guard state(context).insideMultilineClosure,
              case .dollarIdentifier = node.baseName.tokenKind else { return }
        Self.diagnose(
            .preferNamedClosureParam(name: node.baseName.text),
            on: node.baseName,
            context: context
        )
    }
}

fileprivate extension Finding.Message {
    static func preferNamedClosureParam(name: String) -> Finding.Message {
        "use a named parameter instead of '\(name)' in this multi-line closure"
    }
}
