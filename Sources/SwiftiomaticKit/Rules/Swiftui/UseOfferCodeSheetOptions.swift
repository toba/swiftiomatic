import SwiftSyntax

/// Flag the offer code sheet call that the OS 27 StoreKit SDK deprecates.
///
/// The OS 27 StoreKit interface marks `AppStore.presentOfferCodeRedeemSheet(in:)` as
/// `deprecated: 27.0` with the message "Use `presentOfferCodeRedeemSheet(from:options:)` instead."
/// The replacement takes the presenting `UIViewController` and a `Set<RedeemOption>` . It returns
/// the `VerificationResult<Transaction>` of the redemption.
///
/// The `options` parameter has a default value of `[]` . A call with only a `from:` argument
/// therefore resolves to the new method, and the rule does not report it.
///
/// Lint: A call to `presentOfferCodeRedeemSheet` whose only argument has the label `in:` raises a
/// warning.
final class UseOfferCodeSheetOptions: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName
            ?? node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName

        guard let name,
              name.hasText("presentOfferCodeRedeemSheet"),
              node.arguments.count == 1,
              node.arguments.first?.label?.text == "in" else { return .visitChildren }

        diagnose(.useViewControllerForm, on: name)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useViewControllerForm: Finding.Message =
        "'presentOfferCodeRedeemSheet(in:)' is deprecated on OS 27. Call 'presentOfferCodeRedeemSheet(from:options:)' with the presenting view controller"
}
