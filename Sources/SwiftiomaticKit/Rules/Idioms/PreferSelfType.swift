import SwiftSyntax

/// Prefer `Self` over `type(of: self)`.
///
/// Inside a class/struct/enum/actor, `Self` refers to the current type and is fully equivalent to
/// `type(of: self)` for any non-polymorphic dispatch. The shorthand is more concise and avoids
/// the runtime call.
///
/// This rule does not fire at the top level of a file (where `self` does not refer to an enclosing
/// type) or for non-`self` arguments (`type(of: param)` is preserved).
///
/// Lint: A warning is raised for `type(of: self)` (also `Swift.type(of: self)`) inside a type.
///
/// Rewrite: The call is replaced with `Self`.
final class PreferSelfType: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    /// Per-file mutable state held in `Context.ruleState`.
    final class State {
        var typeDepth = 0
    }

    // MARK: - Scope hooks

    static func willEnter(_: ClassDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth += 1
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth -= 1
    }

    static func willEnter(_: StructDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth += 1
    }

    static func didExit(_: StructDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth -= 1
    }

    static func willEnter(_: EnumDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth += 1
    }

    static func didExit(_: EnumDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth -= 1
    }

    static func willEnter(_: ActorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth += 1
    }

    static func didExit(_: ActorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth -= 1
    }

    static func willEnter(_: ExtensionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth += 1
    }

    static func didExit(_: ExtensionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.typeDepth -= 1
    }

    // MARK: - Static transform

    static func transform(
        _ node: MemberAccessExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.typeDepth > 0,
            let baseCall = node.base?.as(FunctionCallExprSyntax.self),
            isTypeOfSelfCall(baseCall)
        else { return ExprSyntax(node) }

        Self.diagnose(.preferSelfType, on: baseCall, context: context)

        let selfRef = DeclReferenceExprSyntax(baseName: .keyword(.Self))
            .with(\.leadingTrivia, baseCall.leadingTrivia)
            .with(\.trailingTrivia, baseCall.trailingTrivia)
        return ExprSyntax(node.with(\.base, ExprSyntax(selfRef)))
    }

    private static func isTypeOfSelfCall(_ call: FunctionCallExprSyntax) -> Bool {
        guard call.arguments.count == 1,
            let firstArg = call.arguments.first,
            firstArg.label?.text == "of",
            firstArg.expression.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
                == .keyword(.self)
        else { return false }

        if let identifier = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return identifier.baseName.text == "type"
        }
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text == "type"
                && memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Swift"
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let preferSelfType: Finding.Message =
        "prefer 'Self' over 'type(of: self)'"
}
