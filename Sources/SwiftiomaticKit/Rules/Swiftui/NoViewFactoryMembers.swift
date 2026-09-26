import SwiftSyntax

/// Flag a type member, other than `body` , that returns `some View` , `AnyView` or a concrete
/// custom view type.
///
/// A factory member runs as part of the caller's `body` . SwiftUI cannot compare its inputs or skip
/// it, so every change the caller sees rebuilds the factory's views too. A separate `View` type
/// gets its own stored inputs, and SwiftUI skips it when they do not change.
///
/// The rule covers members of every type, not only views. A factory on a model type or in a
/// protocol extension runs inside the caller's `body` too.
///
/// A member that returns a concrete custom view type, such as `-> RowView` , is a factory too. The
/// rule counts a return type as a view when a type of that name in the same file conforms to
/// `View` , or, for a type declared elsewhere, when its name ends in `View` and has no AppKit or
/// UIKit prefix such as `NS` or `UI` . A member that returns a concrete leaf type such as `Text` ,
/// `Image` , `Color` , a shape, a gradient or `EmptyView` is not a factory. Neither are the protocol entry points `body` ,
/// `body(content:)` , `makeBody(configuration:)` and `previews` , nor a fluent method in an
/// extension of `View` or a SwiftUI view type such as `Text` that transforms `self` .
///
/// A stored property, such as `let content: AnyView` , is an input to the view and is not a factory.
///
/// Lint: A type member returns `some View` , `any View` , `AnyView` or a concrete custom view type.
final class NoViewFactoryMembers: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// Return types that build an opaque or erased view tree
    private static let factoryReturnTypes: Set<String> = [
        "some View", "some SwiftUI.View", "any View", "any SwiftUI.View", "AnyView",
        "SwiftUI.AnyView",
    ]

    /// The protocol entry points that must return a view
    private static let entryPoints: Set<String> = [
        "body", "body(content:)", "makeBody(configuration:)", "makeNSView(context:)",
        "makeUIView(context:)", "makeNSViewController(context:)",
        "makeUIViewController(context:)",
    ]

    /// Concrete SwiftUI view types whose names end in `View` but that build nothing
    private static let leafViewTypes: Set<String> = ["EmptyView"]

    /// Framework prefixes of platform view classes, such as `NSTextView` or `MTKView`
    private static let platformPrefixes = [
        "NS", "UI", "MTK", "WK", "SK", "SCN", "AV", "MK", "PK", "AR", "PDF", "QL", "CA", "GL",
    ]

    /// The receivers whose extension methods are fluent modifiers that transform `self`
    private static let fluentReceivers: Set<String> = [
        "View", "Text", "Image", "Shape", "InsettableShape", "Label", "Color",
    ]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let returnType = node.signature.returnClause?.type,
              Self.factoryReturnTypes.contains(returnType.trimmedDescription)
                  || isConcreteViewType(returnType, around: node)
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

        // A stored property is an input, not a factory, so only a computed property reports
        for binding in node.bindings where binding.accessorBlock != nil {
            guard let type = binding.typeAnnotation?.type,
                  Self.factoryReturnTypes.contains(type.trimmedDescription)
                      || isConcreteViewType(type, around: node),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  name != "body", !(isStatic && name == "previews") else { continue }
            diagnose(.viewFactory(name), on: node.bindingSpecifier)
        }
        return .visitChildren
    }

    /// Whether `type` names a concrete view type, such as `RowView` or `ScrollView<Text>`
    ///
    /// A type declared in the same file counts when it conforms to `View` . A type declared
    /// elsewhere counts when its name ends in `View` , is not a leaf type such as `EmptyView` , and
    /// has no platform prefix such as `NS` or `UI` .
    private func isConcreteViewType(_ type: TypeSyntax, around node: some SyntaxProtocol) -> Bool {
        guard let name = type.as(IdentifierTypeSyntax.self)?.name.text
            ?? type.as(MemberTypeSyntax.self)?.name.text else { return false }

        if let entry = context.typeMembers(around: node).types[name] { return entry.isView }
        guard name.hasSuffix("View"), !Self.leafViewTypes.contains(name) else { return false }
        return !Self.platformPrefixes.contains { prefix in
            guard name.hasPrefix(prefix) else { return false }
            let next = name.dropFirst(prefix.count).first
            return next?.isUppercase == true
        }
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
