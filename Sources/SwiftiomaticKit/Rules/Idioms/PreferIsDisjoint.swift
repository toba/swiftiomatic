import SwiftSyntax

/// Prefer `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.
///
/// `isDisjoint(with:)` expresses intent more directly and can short-circuit on the first shared
/// element, whereas `intersection(_:)` always builds the full intersection set.
///
/// Lint: A warning is raised on `someSet.intersection(other).isEmpty`.
///
/// Rewrite: Not auto-fixed; the receiver may not be a `Set`, so the rewrite is unsafe in general.
final class PreferIsDisjoint: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    static func transform(
        _ node: MemberAccessExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        if node.declName.baseName.text == "isEmpty",
            let baseCall = node.base?.as(FunctionCallExprSyntax.self),
            let baseCallee = baseCall.calledExpression.as(MemberAccessExprSyntax.self),
            baseCallee.declName.baseName.text == "intersection"
        {
            Self.diagnose(.preferIsDisjoint, on: baseCallee.declName.baseName, context: context)
        }
        return ExprSyntax(node)
    }
}

extension Finding.Message {
    fileprivate static let preferIsDisjoint: Finding.Message =
        "prefer 'isDisjoint(with:)' over 'intersection(_:).isEmpty'"
}
