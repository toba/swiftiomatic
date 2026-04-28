import SwiftSyntax

/// Shared helpers for the inlined `NamedClosureParams` rule. The rule
/// diagnoses `$0`/`$1`/... references inside multi-line closures, so we
/// need a per-closure flag indicating whether the *immediately* enclosing
/// closure spans multiple lines. State lives on `Context.ruleState`. See
/// `Sources/SwiftiomaticKit/Rules/Closures/NamedClosureParams.swift` for
/// the legacy implementation.

final class NamedClosureParamsState {
    /// Stack of `insideMultilineClosure` flags — one entry per nested
    /// `ClosureExprSyntax`. The top of the stack is the innermost closure;
    /// when the stack is empty, we're not inside a closure at all.
    var stack: [Bool] = []

    /// Convenience: whether the innermost enclosing closure is multi-line.
    var insideMultilineClosure: Bool { stack.last ?? false }
}

func namedClosureParamsState(_ context: Context) -> NamedClosureParamsState {
    context.ruleState(for: NamedClosureParams.self) { NamedClosureParamsState() }
}

/// Push the multi-line flag for `node` onto the state stack. Called from
/// the generator-emitted `willEnter(_ ClosureExpr, context:)` hook.
func namedClosureParamsPushClosure(_ node: ClosureExprSyntax, context: Context) {
    let converter = context.sourceLocationConverter
    let startLine = converter.location(
        for: node.leftBrace.positionAfterSkippingLeadingTrivia
    ).line
    let endLine = converter.location(
        for: node.rightBrace.endPositionBeforeTrailingTrivia
    ).line
    namedClosureParamsState(context).stack.append(startLine != endLine)
}

func namedClosureParamsPopClosure(context: Context) {
    let state = namedClosureParamsState(context)
    if !state.stack.isEmpty { state.stack.removeLast() }
}

/// Diagnose `$N` references at the current closure scope.
func namedClosureParamsRewriteDeclReference(
    _ node: DeclReferenceExprSyntax,
    context: Context
) {
    let state = namedClosureParamsState(context)
    guard state.insideMultilineClosure,
          case .dollarIdentifier = node.baseName.tokenKind
    else { return }
    NamedClosureParams.diagnose(
        .preferNamedClosureParam(name: node.baseName.text),
        on: node.baseName,
        context: context
    )
}

extension Finding.Message {
    fileprivate static func preferNamedClosureParam(name: String) -> Finding.Message {
        "use a named parameter instead of '\(name)' in this multi-line closure"
    }
}
