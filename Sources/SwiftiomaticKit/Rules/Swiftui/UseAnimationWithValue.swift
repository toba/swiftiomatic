import SwiftSyntax

/// Flag the one-argument `.animation(_:)` view modifier.
///
/// The one-argument form is deprecated since iOS 15. It animates every change in the view,
/// including changes that must not animate. `.animation(_:value:)` animates only the changes of
/// `value` . The iOS 17 form `.animation(_:body:)` animates only the modifiers in its closure.
///
/// The rule does not flag `Binding.animation(_:)` on a `$` projection, or
/// `AnyTransition.animation(_:)` on a transition such as `.opacity` . These forms are not
/// deprecated.
///
/// Lint: A call `.animation(x)` has exactly one unlabeled argument and no trailing closure.
final class UseAnimationWithValue: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// Base names that start a chain whose `.animation(_:)` is not the view modifier
    private static let nonViewRoots: Set<String> = ["AnyTransition", "Animation", "Transaction"]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "animation",
              let base = member.base,
              node.arguments.count == 1,
              node.arguments.first?.label == nil,
              node.trailingClosure == nil,
              node.additionalTrailingClosures.isEmpty,
              isViewChain(base) else { return .visitChildren }
        diagnose(.oneArgumentAnimation, on: member.declName)
        return .visitChildren
    }

    /// Whether the chain that `base` starts can be a view
    ///
    /// A chain that starts at a `$` projection is a `Binding` . A chain that starts at an implicit
    /// member such as `.opacity` , or at a transition or animation type, is not a view.
    private func isViewChain(_ base: ExprSyntax) -> Bool {
        var current = base

        while true {
            if let call = current.as(FunctionCallExprSyntax.self) {
                current = call.calledExpression
            } else if let member = current.as(MemberAccessExprSyntax.self) {
                guard let inner = member.base else { return false }
                if let reference = inner.as(DeclReferenceExprSyntax.self),
                   reference.baseName.tokenKind == .keyword(.self) {
                    return !member.declName.baseName.text.hasPrefix("$")
                }
                current = inner
            } else if let chaining = current.as(OptionalChainingExprSyntax.self) {
                current = chaining.expression
            } else if let unwrap = current.as(ForceUnwrapExprSyntax.self) {
                current = unwrap.expression
            } else if let subscriptCall = current.as(SubscriptCallExprSyntax.self) {
                current = subscriptCall.calledExpression
            } else if let reference = current.as(DeclReferenceExprSyntax.self) {
                let name = reference.baseName.text
                return !name.hasPrefix("$") && !Self.nonViewRoots.contains(name)
            } else {
                return true
            }
        }
    }
}

fileprivate extension Finding.Message {
    static let oneArgumentAnimation: Finding.Message =
        "'.animation(_:)' without 'value:' is deprecated and animates every change. Use '.animation(_:value:)' or '.animation(_:body:)'"
}
