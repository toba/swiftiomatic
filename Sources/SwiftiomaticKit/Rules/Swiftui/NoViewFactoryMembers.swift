import SwiftSyntax

/// Flag a member of a `View` type, other than `body` , that returns `some View` or `AnyView` .
///
/// A factory member runs as part of the caller's `body` . SwiftUI cannot compare its inputs or skip
/// it, so every change the caller sees rebuilds the factory's views too. A separate `View` type
/// gets its own stored inputs, and SwiftUI skips it when they do not change.
///
/// A member that returns a concrete leaf type such as `Text` , `Image` , `Color` , a shape, a
/// gradient or `EmptyView` is not a factory. Neither are the protocol entry points `body` ,
/// `body(content:)` and `makeBody(configuration:)` , nor a fluent method in `extension View` that
/// transforms `self` .
///
/// Lint: A member of a `View` or `ViewModifier` type returns `some View` , `any View` or `AnyView`
/// .
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

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let returnType = node.signature.returnClause?.type,
              Self.factoryReturnTypes.contains(returnType.trimmedDescription)
        else { return .visitChildren }
        let labels = node.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        let signature = "\(node.name.text)(\(labels.joined()))"

        if !Self.entryPoints.contains(signature), isViewMember(node) {
            diagnose(.viewFactory(node.name.text), on: node.funcKeyword)
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isViewMember(node) else { return .visitChildren }

        for binding in node.bindings {
            guard let type = binding.typeAnnotation?.type,
                  Self.factoryReturnTypes.contains(type.trimmedDescription),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  name != "body" else { continue }
            diagnose(.viewFactory(name), on: node.bindingSpecifier)
        }
        return .visitChildren
    }

    /// Whether `node` is a direct member of a type the file declares as a view
    private func isViewMember(_ node: some SyntaxProtocol) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let name = TypeMemberIndex.enclosingTypeName(of: node) else { return false }
        return context.typeMembers(around: node).types[name]?.isView == true
    }
}

fileprivate extension Finding.Message {
    static func viewFactory(_ name: String) -> Finding.Message {
        "'\(name)' builds a view outside 'body'. Extract it into a 'View' type with its own inputs"
    }
}
