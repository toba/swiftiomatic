import SwiftSyntax

/// Flag a view input that the view stores only to pass it unchanged to a child view.
///
/// A forwarded input makes the parent depend on a value it never reads. Each change to the value
/// makes SwiftUI evaluate the parent's `body` as well as the child's. Build the child in the view
/// that owns the value and pass it in as content, or let the child read the value from its source.
///
/// A binding and a closure are exempt, because a child needs them to write back or to act. So is an
/// input that the view reads, adapts or passes to two different children. A built-in SwiftUI view
/// such as `Text` or `Image` renders the value, so passing it there counts as a read.
///
/// Lint: Every use of a stored value input of a view type, outside its initializers, is an argument
/// of one call to an uppercase callee, passed as `name` or `self.name` .
final class NoForwardedViewInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.attributes.firstAttributeName != "Binding",
              let entry = context.viewEntry(forMember: node),
              let viewName = TypeMemberIndex.enclosingTypeName(of: node) else { return .skipChildren }
        let regions = TypeMemberIndex.declarationRegions(ofMember: node, typeName: viewName)

        for input in node.viewInputs where input.type.functionType == nil {
            if let child = Self.forwardingChild(of: input.name, entry: entry, regions: regions) {
                diagnose(.forwardedInput(input.name, child), on: node)
            }
        }
        return .skipChildren
    }

    /// The one child that receives every use of `name` unchanged, or `nil` for any other use
    private static func forwardingChild(
        of name: String,
        entry: TypeMemberIndex.TypeEntry,
        regions: [any DeclGroupSyntax]
    ) -> String? {
        var child: String?

        for region in regions {
            for item in region.memberBlock.members where !item.decl.is(InitializerDeclSyntax.self) {
                for reference in TypeMemberIndex.references(in: item.decl, of: entry)
                where reference.name == name {
                    guard reference.spelling == name,
                          let callee = forwardedCallee(reference.node),
                          child == nil || child == callee else { return nil }
                    child = callee
                }
            }
        }
        return child
    }

    /// The callee name when `reference` is a whole argument of a call to an uppercase callee
    private static func forwardedCallee(_ reference: DeclReferenceExprSyntax) -> String? {
        guard let labeled = reference.selfQualifiedUse.parent?.as(LabeledExprSyntax.self),
              let call = labeled.parent?.parent?.as(FunctionCallExprSyntax.self),
              let callee = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
                ?? call.calledExpression.as(GenericSpecializationExprSyntax.self)?.expression
                .as(DeclReferenceExprSyntax.self)?.baseName.text,
              callee.first?.isUppercase == true,
              !SwiftUIBuiltInViews.names.contains(callee) else { return nil }
        return callee
    }
}

fileprivate extension Finding.Message {
    static func forwardedInput(_ name: String, _ child: String) -> Finding.Message {
        "'\(name)' is stored only to pass it unchanged to '\(child)'. Build the child in the parent and pass it in as content, or let the child read the value itself"
    }
}
