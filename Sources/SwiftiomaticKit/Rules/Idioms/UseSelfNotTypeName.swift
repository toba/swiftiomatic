import SwiftSyntax

/// Prefer `Self` over `type(of: self)` .
///
/// Inside a struct, an enum, an actor or a final class, `Self` names the same type that
/// `type(of: self)` returns at runtime. The shorthand is more concise and avoids the runtime call.
///
/// The rule stays silent everywhere the two can differ. A subclass instance inside a non-final
/// class body, and a conforming type inside a protocol extension, both carry a dynamic type that
/// `Self` does not name, so replacing the call there changes which implementation runs. An
/// extension body never states the kind of the type it extends, so every extension counts as
/// unsafe.
///
/// The rule also stays silent at the top level of a file, where `self` refers to no enclosing
/// type, and for a non- `self` argument, where `type(of: param)` is preserved.
///
/// Lint: A warning is raised for `type(of: self)` (also `Swift.type(of: self)` ) inside a struct,
/// an enum, an actor or a final class.
///
/// Rewrite: The call is replaced with `Self` .
final class UseSelfNotTypeName: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        /// One entry per enclosing type or extension body. An entry is true when `Self` is
        /// guaranteed to name the dynamic type of `self` in that body.
        var selfNamesDynamicType: [Bool] = []
    }

    // MARK: - Scope hooks

    private static func push(_ selfNamesDynamicType: Bool, _ context: Context) {
        context.preferSelfTypeState.selfNamesDynamicType.append(selfNamesDynamicType)
    }

    /// Pops the innermost scope. A hook that runs without its paired `willEnter` leaves the stack
    /// empty, and an unguarded `removeLast` would trap.
    private static func pop(_ context: Context) {
        let state = context.preferSelfTypeState
        if !state.selfNamesDynamicType.isEmpty { state.selfNamesDynamicType.removeLast() }
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        // a subclass instance has a dynamic type that `Self` does not name
        push(node.modifiers.contains { $0.name.tokenKind == .keyword(.final) }, context)
    }

    static func didExit(_: ClassDeclSyntax, context: Context) { pop(context) }

    static func willEnter(_: StructDeclSyntax, context: Context) { push(true, context) }

    static func didExit(_: StructDeclSyntax, context: Context) { pop(context) }

    static func willEnter(_: EnumDeclSyntax, context: Context) { push(true, context) }

    static func didExit(_: EnumDeclSyntax, context: Context) { pop(context) }

    static func willEnter(_: ActorDeclSyntax, context: Context) {
        // an actor takes no subclass, so `Self` is exact
        push(true, context)
    }

    static func didExit(_: ActorDeclSyntax, context: Context) { pop(context) }

    static func willEnter(_: ExtensionDeclSyntax, context: Context) {
        // the extended type may be a protocol or a base class, and the syntax does not say which
        push(false, context)
    }

    static func didExit(_: ExtensionDeclSyntax, context: Context) { pop(context) }

    // MARK: - Static transform

    static func transform(
        _ node: MemberAccessExprSyntax,
        original _: MemberAccessExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let state = context.preferSelfTypeState
        guard state.selfNamesDynamicType.last == true,
              let baseCall = node.base?.as(FunctionCallExprSyntax.self),
              isTypeOfSelfCall(baseCall) else { return ExprSyntax(node) }

        Self.diagnose(.useSelfNotTypeName, on: baseCall, context: context)

        let selfRef = DeclReferenceExprSyntax(baseName: .keyword(.Self))
            .with(\.leadingTrivia, baseCall.leadingTrivia)
            .with(\.trailingTrivia, baseCall.trailingTrivia)
        return ExprSyntax(node.with(\.base, ExprSyntax(selfRef)))
    }

    private static func isTypeOfSelfCall(_ call: FunctionCallExprSyntax) -> Bool {
        guard call.arguments.count == 1,
              let firstArg = call.arguments.first,
              firstArg.label?.text == "of",
              firstArg.expression.as(DeclReferenceExprSyntax.self)?.baseName
                  .tokenKind
                  == .keyword(.self) else { return false }

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

fileprivate extension Finding.Message {
    static let useSelfNotTypeName: Finding.Message = "prefer 'Self' over 'type(of: self)'"
}
