import SwiftSyntax

/// Flag `Subprocess.run(...)` calls that omit `platformOptions:` (or pass a default
/// `PlatformOptions()`). Without an explicit teardown sequence, a cancelled or thrown task can leak
/// the child process — it stays alive until parent exit. The fix is to pass
/// `PlatformOptions(teardownSequence: [...])` matching the child's signal handling.
///
/// Flag-only — choosing the right teardown sequence (signals, intervals) is contextual.
final class RequireSubprocessTeardownSequence: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "run",
            let base = member.base?.as(DeclReferenceExprSyntax.self),
            base.baseName.text == "Subprocess" else { return .visitChildren }

        if let platformOptions = node.arguments.first(where: { $0.label?.text == "platformOptions" }
        ) {
            if isDefaultPlatformOptions(platformOptions.expression) {
                diagnose(.subprocessDefaultPlatformOptions, on: platformOptions)
            }
        } else {
            diagnose(.subprocessMissingPlatformOptions, on: node.calledExpression)
        }
        return .visitChildren
    }

    /// Matches `PlatformOptions()` with no arguments — the default-constructed value with no
    /// teardown sequence.
    private func isDefaultPlatformOptions(_ expr: ExprSyntax) -> Bool {
        guard let call = expr.as(FunctionCallExprSyntax.self),
              call.arguments.isEmpty,
              let ident = call.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "PlatformOptions" else { return false }
        return true
    }
}

fileprivate extension Finding.Message {
    static let subprocessMissingPlatformOptions: Finding.Message =
        "'Subprocess.run' without 'platformOptions:' can orphan the child on cancellation — pass 'PlatformOptions(teardownSequence: [...])'"
    static let subprocessDefaultPlatformOptions: Finding.Message =
        "default 'PlatformOptions()' has no teardown sequence — pass 'PlatformOptions(teardownSequence: [...])' to avoid orphaned children on cancellation"
}
