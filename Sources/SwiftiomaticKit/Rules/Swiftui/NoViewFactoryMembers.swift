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
/// `Image` , `Color` , a shape, a gradient or `EmptyView` is not a factory. Neither are the
/// protocol entry points `body` , `body(content:)` , `makeBody(configuration:)` and `previews` .
///
/// A method in an extension of `View` or `Shape` that takes parameters and transforms `self` is a
/// modifier, not a factory. The rule reports such a member when it takes no parameters, because
/// then it applies a fixed composition that belongs in a `ViewModifier` or a `View` type. The rule
/// also reports a member in an extension of a concrete type such as `Text` that returns a different
/// view type, because the result loses the concrete type that makes `Text` an exception.
///
/// The rule also reports a `View` type that holds a factory member, once, at the type's name. The
/// type is the place where the extracted views get their inputs.
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

    /// The protocols whose extension methods with parameters are fluent modifiers of `self`
    private static let fluentReceivers: Set<String> = ["View", "Shape", "InsettableShape"]

    /// The name tokens of the owner declarations that already have a finding
    private var reportedOwners: Set<SyntaxIdentifier> = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let returnType = node.signature.returnClause?.type,
              Self.factoryReturnTypes.contains(returnType.trimmedDescription)
                  || isConcreteViewType(returnType, around: node)
        else { return .visitChildren }
        let labels = node.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        let signature = "\(node.name.text)(\(labels.joined()))"

        let hasParameters = !node.signature.parameterClause.parameters.isEmpty

        if !Self.entryPoints.contains(signature),
           isFactoryOwnerMember(node, hasParameters: hasParameters) {
            diagnose(.viewFactory(node.name.text), on: node.funcKeyword)
            diagnoseOwner(of: node)
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isFactoryOwnerMember(node, hasParameters: false) else { return .visitChildren }
        let isStatic = node.modifiers.contains { $0.name.tokenKind == .keyword(.static) }

        // A stored property is an input, not a factory, so only a computed property reports
        for binding in node.bindings where binding.accessorBlock != nil {
            guard let type = binding.typeAnnotation?.type,
                  Self.factoryReturnTypes.contains(type.trimmedDescription)
                      || isConcreteViewType(type, around: node),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  name != "body", !(isStatic && name == "previews") else { continue }
            diagnose(.viewFactory(name), on: node.bindingSpecifier)
            diagnoseOwner(of: node)
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
    /// such as `View` holds modifiers that transform `self` . A member there is a factory only
    /// when it takes no parameters.
    private func isFactoryOwnerMember(_ node: some SyntaxProtocol, hasParameters: Bool) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let owner = TypeMemberIndex.owningDeclaration(of: node),
              !owner.is(ProtocolDeclSyntax.self) else { return false }

        if let ext = owner.as(ExtensionDeclSyntax.self) {
            let extended = ext.extendedType.trimmedDescription
            let simple = extended.hasPrefix("SwiftUI.") ? String(extended.dropFirst(8)) : extended
            return !(Self.fluentReceivers.contains(simple) && hasParameters)
        }
        return true
    }

    /// Reports the `View` type declaration that holds the factory member `node` , once
    ///
    /// A factory in an extension reports the type declaration of the same name in the file.
    private func diagnoseOwner(of node: some SyntaxProtocol) {
        guard let owner = TypeMemberIndex.owningDeclaration(of: node),
              let token = TypeMemberIndex.typeNameToken(of: owner),
              context.typeMembers(around: node).types[token.text]?.isView == true,
              reportedOwners.insert(token.id).inserted else { return }
        diagnose(.viewFactoryOwner(token.text), on: token)
    }
}

fileprivate extension Finding.Message {
    static func viewFactory(_ name: String) -> Finding.Message {
        "'\(name)' builds a view outside 'body'. Extract it into a 'View' type with its own inputs"
    }

    static func viewFactoryOwner(_ name: String) -> Finding.Message {
        "'\(name)' builds part of its view in helper members. Move each helper into a focused 'View' type"
    }
}
