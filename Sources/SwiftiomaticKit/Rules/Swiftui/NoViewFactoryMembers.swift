import SwiftSyntax

/// Flag a type member, other than `body` , that returns `some View` or `AnyView` .
///
/// A factory member runs as part of the caller's `body` . SwiftUI cannot compare its inputs or skip
/// it, so every change the caller sees rebuilds the factory's views too. A separate `View` type
/// gets its own stored inputs, and SwiftUI skips it when they do not change.
///
/// The rule covers members of every type, not only views. A factory on a model type or in a
/// protocol extension runs inside the caller's `body` too.
///
/// A member that returns a concrete leaf type such as `Text` , `Image` , `Color` , a shape, a
/// gradient or `EmptyView` is not a factory. Neither are the protocol entry points `body` ,
/// `body(content:)` , `makeBody(configuration:)` and `previews` , nor a fluent method in an
/// extension of `View` or a SwiftUI view type such as `Text` that transforms `self` .
///
/// Lint: A type member returns `some View` , `any View` or `AnyView` .
final class NoViewFactoryMembers: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// Return types that build an opaque or erased view tree
    private static let factoryReturnTypes: Set<String> = [
        "some View", "some SwiftUI.View", "any View", "any SwiftUI.View", "AnyView",
        "SwiftUI.AnyView",
    ]

    /// The protocol entry points that must return a view
    private static let entryPoints: Set<String> = [
        "body", "body(content:)", "makeBody(configuration:)",
    ]

    /// The receivers whose extension methods are fluent modifiers that transform `self`
    private static let fluentReceivers: Set<String> = [
        "View", "Text", "Image", "Shape", "InsettableShape", "Label", "Color",
    ]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let returnType = node.signature.returnClause?.type,
              Self.factoryReturnTypes.contains(returnType.trimmedDescription)
        else { return .visitChildren }
        let labels = node.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        let signature = "\(node.name.text)(\(labels.joined()))"

        if !Self.entryPoints.contains(signature), isFactoryOwnerMember(node) {
            diagnose(.viewFactory(node.name.text), on: node.funcKeyword)
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isFactoryOwnerMember(node) else { return .visitChildren }
        let isStatic = node.modifiers.contains { $0.name.tokenKind == .keyword(.static) }

        for binding in node.bindings {
            guard let type = binding.typeAnnotation?.type,
                  Self.factoryReturnTypes.contains(type.trimmedDescription),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  name != "body", !(isStatic && name == "previews") else { continue }
            diagnose(.viewFactory(name), on: node.bindingSpecifier)
        }
        return .visitChildren
    }

    /// Whether `node` is a direct member of a type or an extension that can hold a factory.
    ///
    /// A protocol requirement has no body, so it builds nothing. An extension of a fluent receiver
    /// such as `View` holds modifiers that transform `self` .
    private func isFactoryOwnerMember(_ node: some SyntaxProtocol) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let owner = TypeMemberIndex.owningDeclaration(of: node),
              !owner.is(ProtocolDeclSyntax.self) else { return false }

        if let ext = owner.as(ExtensionDeclSyntax.self) {
            let extended = ext.extendedType.trimmedDescription
            let simple = extended.hasPrefix("SwiftUI.") ? String(extended.dropFirst(8)) : extended
            return !Self.fluentReceivers.contains(simple)
        }
        return true
    }
}

fileprivate extension Finding.Message {
    static func viewFactory(_ name: String) -> Finding.Message {
        "'\(name)' builds a view outside 'body'. Extract it into a 'View' type with its own inputs"
    }
}
