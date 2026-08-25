import SwiftSyntax

/// Flag async cleanup in a `defer` that a cancelled task may skip.
///
/// A cancelled task keeps running, and the APIs it calls observe the cancellation. Cleanup that
/// calls one of those APIs can return early and leave the resource open. SE-0504 adds
/// `withTaskCancellationShield` , which hides the cancellation from the scope it wraps so the
/// cleanup runs to completion.
///
/// ```swift
/// defer {
///     await withTaskCancellationShield { await connection.close() }
/// }
/// ```
///
/// **Off by default.** Whether a given call observes cancellation is not visible at the call site,
/// so this rule cannot tell a cleanup that needs the shield from one that does not. It fires on
/// every awaiting `defer` . Turn it on for a codebase that wants the shield as a standing rule for
/// cleanup, and leave it off otherwise.
///
/// Lint: An `await` inside a `defer` body that is not already inside a `withTaskCancellationShield`
/// raises a warning.
final class UseTaskCancellationShield: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    override func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
        for awaitKeyword in node.body.unshieldedAwaits {
            diagnose(.useCancellationShield, on: awaitKeyword)
        }
        return .visitChildren
    }
}

fileprivate extension CodeBlockSyntax {
    /// Every `await` keyword the deferred cleanup itself runs unshielded.
    ///
    /// The shield's own `await` is skipped, because that one is the fix rather than the defect. So
    /// is an `await` behind a nested closure: it belongs to that closure, and in the common
    /// `defer { Task { await close() } }` shape it runs in an unstructured task the shield cannot
    /// reach. `UseAsyncDeferNotTask` owns that shape.
    var unshieldedAwaits: [TokenSyntax] {
        var found = [TokenSyntax]()

        for token in tokens(viewMode: .sourceAccurate) where token.tokenKind == .keyword(.await) {
            guard case .directlyDeferred = token.deferPlacement else { continue }
            found.append(token)
        }
        return found
    }
}

/// Where an `await` inside a `defer` body sits, relative to the cleanup the rule reports on.
private enum DeferPlacement { case directlyDeferred, shielded, nested }

fileprivate extension TokenSyntax {
    /// Where this `await` sits inside the enclosing `defer` .
    var deferPlacement: DeferPlacement {
        if awaitsTheShieldItself { return .shielded }

        var current = Syntax(self).parent

        while let node = current {
            if node.is(DeferStmtSyntax.self) { return .directlyDeferred }

            // A closure ends the search, because whatever runs it owns the await. The one exception
            // is the shield's own body, which is still the deferred cleanup.
            if node.is(ClosureExprSyntax.self) {
                let owner = node.parent?.as(FunctionCallExprSyntax.self)
                return owner?.isCancellationShield == true ? .shielded : .nested
            }
            current = node.parent
        }
        return .nested
    }

    /// Whether this `await` is the one applied to the shield call itself.
    var awaitsTheShieldItself: Bool {
        guard let expression = Syntax(self).parent?.as(AwaitExprSyntax.self)?.expression,
              let call = expression.as(FunctionCallExprSyntax.self) else { return false }
        return call.isCancellationShield
    }
}

fileprivate extension FunctionCallExprSyntax {
    var isCancellationShield: Bool {
        calledExpression.as(DeclReferenceExprSyntax.self)?.baseName
            .text
            == "withTaskCancellationShield"
    }
}

fileprivate extension Finding.Message {
    static let useCancellationShield: Finding.Message =
        "a cancelled task can skip this cleanup — wrap it in 'withTaskCancellationShield' so it runs to completion (SE-0504)"
}
