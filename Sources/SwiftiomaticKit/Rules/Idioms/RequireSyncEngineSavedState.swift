import SwiftSyntax

/// Require the saved state when the code creates a `CKSyncEngine.Configuration` .
///
/// `CKSyncEngine` sends a `.stateUpdate` event each time its state changes. The app saves that
/// state and passes it back as `stateSerialization` on the next launch. A literal `nil` makes the
/// engine start with no state. It then reports a spurious sign-in and fetches every record again.
///
/// The rule reports only the literal `nil` . A variable that holds `nil` on the first launch is the
/// correct form.
///
/// Lint: `CKSyncEngine.Configuration(...)` has the argument `stateSerialization: nil` .
final class RequireSyncEngineSavedState: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard Self.isSyncEngineConfiguration(node.calledExpression) else { return .visitChildren }

        for argument in node.arguments
        where argument.label?.text == "stateSerialization"
            && argument.expression.is(NilLiteralExprSyntax.self)
        {
            diagnose(.nilStateSerialization, on: argument)
        }
        return .visitChildren
    }

    /// Whether `callee` is `CKSyncEngine.Configuration` or `CKSyncEngine.Configuration.init`
    private static func isSyncEngineConfiguration(_ callee: ExprSyntax) -> Bool {
        var expr = callee

        if let member = expr.as(MemberAccessExprSyntax.self),
           member.declName.baseName.tokenKind == .keyword(.`init`),
           let base = member.base { expr = base }
        guard let member = expr.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "Configuration",
              let base = member.base?.as(DeclReferenceExprSyntax.self) else { return false }
        return base.baseName.text == "CKSyncEngine"
    }
}

fileprivate extension Finding.Message {
    static let nilStateSerialization: Finding.Message =
        "'stateSerialization: nil' makes the sync engine start over on every launch; pass the state that the last '.stateUpdate' event saved"
}
