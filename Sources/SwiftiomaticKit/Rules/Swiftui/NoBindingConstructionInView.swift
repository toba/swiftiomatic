import SwiftSyntax

/// Flag a `Binding(get:set:)` that a view builds in its body, in a helper, or in a closure.
///
/// A binding built from closures is a new value on each update. SwiftUI cannot compare two closure
/// bindings, so each child view that receives one is always different from its last value and
/// updates each time the parent does. The closures also capture the current values of the view, and
/// the code that they hold is hidden from the owner of the state.
///
/// Project the binding with `$` from the owner of the value. When the binding needs logic, move
/// that logic into the model, for example as a computed property with a setter, and project a
/// binding to that property.
///
/// The rule reports each `Binding(get:set:)` in a member of a type that conforms to `View` or
/// `ViewModifier` in the same file. A binding that a model or another type builds is not reported.
///
/// Lint: A member of a view type calls `Binding(get:set:)` .
final class NoBindingConstructionInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard Self.isBindingInitializer(node),
              node.arguments.contains(where: { $0.label?.text == "get" }),
              node.arguments.contains(where: { $0.label?.text == "set" }),
              context.typeMembers(around: node).enclosingType(of: node)?.isView == true
        else { return .visitChildren }
        diagnose(.bindingInView, on: node)
        return .visitChildren
    }

    /// Whether `node` calls `Binding` , `Binding<T>` , `SwiftUI.Binding` or `Binding.init`
    private static func isBindingInitializer(_ node: FunctionCallExprSyntax) -> Bool {
        var callee = node.calledExpression

        if let member = callee.as(MemberAccessExprSyntax.self),
           member.declName.baseName.tokenKind == .keyword(.`init`),
           let base = member.base { callee = base }

        if let generic = callee.as(GenericSpecializationExprSyntax.self) {
            callee = generic.expression
        }

        if let member = callee.as(MemberAccessExprSyntax.self),
           member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "SwiftUI" {
            return member.declName.baseName.text == "Binding"
        }
        return callee.as(DeclReferenceExprSyntax.self)?.baseName.text == "Binding"
    }
}

fileprivate extension Finding.Message {
    static let bindingInView: Finding.Message = """
        'Binding(get:set:)' built in a view gives a new binding each update, and SwiftUI cannot \
        compare it. Project a binding with '$' from the owner of the value, or move the logic into \
        the model
        """
}
