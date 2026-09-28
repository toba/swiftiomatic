import SwiftSyntax

/// Flag a type member, other than `body` , that returns `some View` , `AnyView` or a concrete
/// custom view type.
///
/// A factory member runs as part of the caller's `body` . SwiftUI cannot compare its inputs or skip
/// it, so every change the caller sees rebuilds the factory's views too. Move the member into a
/// focused `View` type, such as `struct HabitatSection: View { let habitatID: Habitat.ID }`. The
/// `View` type gets its own stored inputs, and SwiftUI skips its `body` when they do not change.
/// Pass only the values that the new type reads. When you extract, keep the bindings, the captured
/// values and the identity-sensitive behavior of the original code. Pass a `Binding` where the
/// helper wrote state, and keep the same `id` and conditional structure.
///
/// The rule covers members of every type, not only views. A factory on a model type or in a
/// protocol extension runs inside the caller's `body` too.
///
/// A member that returns a concrete custom view type, such as `-> RowView` , is a factory too. The
/// rule counts a return type as a view when a type of that name in the same file conforms to `View`
/// , or, for a type declared elsewhere, when its name ends in `View` and has no AppKit or UIKit
/// prefix such as `NS` or `UI` . A SwiftUI container or control, such as `HStack<Text>` ,
/// `List<...>` or `Button<Text>` , counts as a view too. A member that returns a concrete leaf type
/// such as `Text` , `Image` , `Color` , a shape, a gradient or `EmptyView` is not a factory.
/// Neither are the protocol entry points `body` , `body(content:)` , `makeBody(configuration:)` and
/// `previews` .
///
/// A member in an extension of `View` or `Shape` that transforms `self` is a modifier, not a
/// factory. A member counts as a modifier when it takes parameters, or when its only statement is a
/// modifier chain on `self` , such as `padding().background(.thinMaterial)` . A member there that
/// takes no parameters and builds a new view, such as `Text("None")` , is a factory. The rule also
/// reports a member in an extension of a concrete type such as `Text` that returns a different view
/// type, because the result loses the concrete type that makes `Text` an exception.
///
/// The rule also reports a `View` type that holds a factory member, once, at the type's name. The
/// type is the place where the extracted views get their inputs.
///
/// A stored property, such as `let content: AnyView` , is an input to the view and is not a
/// factory.
///
/// Lint: A type member returns `some View` , `any View` , `AnyView` , a concrete custom view type,
/// or a SwiftUI container or control.
final class NoViewFactoryMembers: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .mustNot }

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

    /// Concrete SwiftUI containers and controls. Their names do not end in `View` , but a member
    /// that returns one builds a view tree.
    private static let containerTypes: Set<String> = [
        "HStack", "VStack", "ZStack", "LazyHStack", "LazyVStack", "LazyHGrid", "LazyVGrid", "Grid",
        "GridRow", "Group", "Section", "List", "Form", "Table", "NavigationStack",
        "NavigationSplitView", "TabView", "ForEach", "Button", "Label", "Toggle", "Picker", "Menu",
        "DisclosureGroup", "GroupBox", "ControlGroup", "LabeledContent", "Link", "ModifiedContent",
        "TupleView", "ViewThatFits",
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
                  || isConcreteViewType(returnType, around: node) else { return .visitChildren }
        let labels = node.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        let signature = "\(node.name.text)(\(labels.joined()))"

        let isModifier = !node.signature.parameterClause.parameters.isEmpty
            || node.body.map { Self.transformsSelf($0.statements) } == true

        if !Self.entryPoints.contains(signature),
           isFactoryOwnerMember(node, isModifier: isModifier)
        {
            diagnose(.viewFactory(node.name.text), on: node.funcKeyword)
            diagnoseOwner(of: node)
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let isStatic = node.modifiers.contains { $0.name.tokenKind == .keyword(.static) }

        // A stored property is an input, not a factory, so only a computed property reports
        for binding in node.bindings where binding.accessorBlock != nil {
            let getter: CodeBlockItemListSyntax? =
                switch binding.accessorBlock?.accessors {
                    case let .getter(statements): statements
                    case let .accessors(list):
                        list.first { $0.accessorSpecifier.tokenKind == .keyword(.get) }?.body?
                            .statements
                    case nil: nil
                }
            guard isFactoryOwnerMember(node, isModifier: getter.map(Self.transformsSelf) == true),
                  let type = binding.typeAnnotation?.type,
                  Self.factoryReturnTypes.contains(type.trimmedDescription)
                      || isConcreteViewType(type, around: node),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  name != "body",
                  !(isStatic && name == "previews") else { continue }
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
        guard let name = type.simpleName else { return false }
        if Self.containerTypes.contains(name) { return true }

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
    /// such as `View` holds modifiers that transform `self` . A member there is a factory only when
    /// it is not a modifier: it takes no parameters and builds a new view instead of a chain on
    /// `self` .
    private func isFactoryOwnerMember(_ node: some SyntaxProtocol, isModifier: Bool) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let owner = TypeMemberIndex.owningDeclaration(of: node),
              !owner.is(ProtocolDeclSyntax.self) else { return false }

        if let ext = owner.as(ExtensionDeclSyntax.self) {
            let extended = ext.extendedType.trimmedDescription
            let simple = extended.hasPrefix("SwiftUI.") ? String(extended.dropFirst(8)) : extended
            return !(Self.fluentReceivers.contains(simple) && isModifier)
        }
        return true
    }

    /// Whether the only statement of `statements` is a modifier chain on `self` , written as
    /// `self.padding()` , `padding()` or `self`
    private static func transformsSelf(_ statements: CodeBlockItemListSyntax) -> Bool {
        guard let item = statements.firstAndOnly else { return false }
        guard let root = item.expressionOrReturnedValue?.modifierChainRoot else { return false }

        if let reference = root.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.tokenKind == .keyword(.self)
        }
        // An implicit `self` call such as `padding()` names a method, not a type
        guard let callee = root.as(FunctionCallExprSyntax.self)?.calledExpression
            .as(DeclReferenceExprSyntax.self)?.baseName.text,
              let first = callee.first else { return false }
        return first.isLowercase
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
