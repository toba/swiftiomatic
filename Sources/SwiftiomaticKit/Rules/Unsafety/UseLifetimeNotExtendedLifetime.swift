import SwiftSyntax

/// Flag `withExtendedLifetime` in favour of the `@_lifetime` annotation added by Swift 6.3.
///
/// `withExtendedLifetime` states a lifetime dependency at one call site, so every other caller has
/// to rediscover the same rule and repeat it. `@_lifetime(borrow source)` states the dependency in
/// the signature once, and the compiler then enforces it for every caller.
///
/// Lint: A call to `withExtendedLifetime` raises a warning.
final class UseLifetimeNotExtendedLifetime: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let reference = node.calledExpression.as(DeclReferenceExprSyntax.self),
            reference.baseName.text == "withExtendedLifetime" else { return .visitChildren }

        diagnose(.useLifetimeAnnotation, on: reference.baseName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useLifetimeAnnotation: Finding.Message =
        "'withExtendedLifetime' states the dependency at the call site — move it into the signature with '@_lifetime(borrow source)' so the compiler enforces it for every caller"
}
