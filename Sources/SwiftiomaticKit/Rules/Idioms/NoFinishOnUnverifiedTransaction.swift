import SwiftSyntax

/// Flag a `finish()` call in the `.unverified` case of a StoreKit verification result.
///
/// `finish()` tells the App Store that the app delivered the content of a transaction. StoreKit
/// then removes the transaction from `Transaction.unfinished` and does not deliver it again. An
/// unverified transaction failed the signature check, so the app must not deliver its content. To
/// finish it hides the failure, and the app loses the chance to verify the transaction later.
///
/// Finish a transaction only in the `.verified` case, after the app delivers the content.
///
/// The rule reads the body of a `case .unverified` switch case and the body of an
/// `if case .unverified = ...` statement. It matches a call `x.finish()` with no arguments.
///
/// Lint: The `.unverified` branch of a verification result calls `finish()` .
final class NoFinishOnUnverifiedTransaction: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .mustNot }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.arguments.isEmpty,
              node.trailingClosure == nil,
              let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil,
              member.declName.baseName.text == "finish",
              member.declName.argumentNames == nil,
              Self.isInsideUnverifiedBranch(node) else { return .visitChildren }
        diagnose(.finishUnverified, on: node)
        return .visitChildren
    }

    /// Whether the innermost switch case or `if case` body that holds `node` matches
    /// `.unverified`
    private static func isInsideUnverifiedBranch(_ node: some SyntaxProtocol) -> Bool {
        var child = Syntax(node)
        var current = node.parent

        while let ancestor = current {
            if let switchCase = ancestor.as(SwitchCaseSyntax.self) {
                guard let label = switchCase.label.as(SwitchCaseLabelSyntax.self) else {
                    return false
                }
                return label.caseItems.contains { matchesUnverified($0.pattern) }
            }
            if let ifExpr = ancestor.as(IfExprSyntax.self), ifExpr.body.id == child.id,
               ifExpr.conditions.contains(where: { element in
                   element.condition.as(MatchingPatternConditionSyntax.self)
                       .map { matchesUnverified($0.pattern) } ?? false
               })
            {
                return true
            }
            if ancestor.is(FunctionDeclSyntax.self) || ancestor.is(InitializerDeclSyntax.self)
                || ancestor.is(AccessorDeclSyntax.self) || ancestor.is(MemberBlockSyntax.self)
            {
                return false
            }
            child = ancestor
            current = ancestor.parent
        }
        return false
    }

    /// Whether `pattern` names the enum case `.unverified`
    private static func matchesUnverified(_ pattern: PatternSyntax) -> Bool {
        pattern.tokens(viewMode: .sourceAccurate).contains { token in
            token.tokenKind == .identifier("unverified")
                && token.previousToken(viewMode: .sourceAccurate)?.tokenKind == .period
        }
    }
}

fileprivate extension Finding.Message {
    static let finishUnverified: Finding.Message =
        "do not call 'finish()' on an unverified transaction. Finish a transaction only after you verify it and deliver the content"
}
