import SwiftSyntax

/// Flag an unstructured `Task` used to run async cleanup inside a `defer` .
///
/// SE-0493 lets a `defer` body await, so the cleanup runs before the enclosing scope exits. The
/// `Task` form only schedules the work, which means the scope exits first and the ordering is
/// unspecified. A cancelled parent may also drop the task before it starts.
///
/// The rule fires only inside an `async` scope, because a `defer` in a synchronous scope still
/// cannot await.
///
/// Lint: A `Task` , `Task.detached` , `Task.immediate` or `Task.immediateDetached` call at
/// statement level in a `defer` body raises a warning.
final class UseAsyncDeferNotTask: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
        guard node.isInAsyncScope else { return .visitChildren }

        for statement in node.body.statements {
            guard case let .expr(expression) = statement.item,
                  let call = expression.as(FunctionCallExprSyntax.self),
                  let anchor = call.unstructuredTaskAnchor else { continue }
            diagnose(.useAsyncDefer, on: anchor)
        }
        return .visitChildren
    }
}

fileprivate extension DeferStmtSyntax {
    /// Whether the nearest enclosing function, initializer, accessor or closure is `async` .
    ///
    /// The nearest enclosing scope is the one that decides, so the walk stops at the first of them
    /// rather than running to the top of the file. A synchronous closure inside an `async` function
    /// still cannot await.
    var isInAsyncScope: Bool {
        var current = Syntax(self).parent

        while let node = current {
            if let function = node.as(FunctionDeclSyntax.self) {
                return function.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            if let initializer = node.as(InitializerDeclSyntax.self) {
                return initializer.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            if let accessor = node.as(AccessorDeclSyntax.self) {
                return accessor.effectSpecifiers?.asyncSpecifier != nil
            }
            if let closure = node.as(ClosureExprSyntax.self) {
                return closure.isAsync(ignoring: self)
            }
            current = node.parent
        }
        return false
    }
}

fileprivate extension ClosureExprSyntax {
    /// Whether the closure runs async work, so a `defer` in it may await.
    ///
    /// A closure states its effect only when the author writes one, so three signals stand in for
    /// the type checker. The signature may say `async` . The closure may be the body of a `Task` ,
    /// which is always async. Or the body may already await somewhere outside `excluded` .
    ///
    /// `excluded` is the `defer` under review. Its own `await` cannot count, because the whole
    /// point of the rule is to put one there.
    ///
    /// The last signal misses a closure whose only async work is the cleanup itself. That is the
    /// safe direction to miss in: proposing an `await` inside a synchronous closure would break the
    /// build, and a rule that breaks the build is worse than a rule that stays quiet.
    func isAsync(ignoring excluded: some SyntaxProtocol) -> Bool {
        if signature?.effectSpecifiers?.asyncSpecifier != nil { return true }

        if let call = parent?.as(FunctionCallExprSyntax.self), call.taskCall != nil { return true }

        let excludedRange = excluded.position..<excluded.endPosition
        return statements.tokens(viewMode: .sourceAccurate).contains { token in
            token.tokenKind == .keyword(.await) && !excludedRange.contains(token.position)
        }
    }
}

fileprivate extension FunctionCallExprSyntax {
    /// The token to anchor a finding on when this call creates an unstructured task, else `nil` .
    var unstructuredTaskAnchor: TokenSyntax? {
        guard createsUnstructuredTask else { return nil }
        return taskCall?.anchor
    }
}

fileprivate extension Finding.Message {
    static let useAsyncDefer: Finding.Message =
        "a 'defer' body may await (SE-0493) — drop the 'Task' and call the cleanup directly so it finishes before the scope exits"
}
