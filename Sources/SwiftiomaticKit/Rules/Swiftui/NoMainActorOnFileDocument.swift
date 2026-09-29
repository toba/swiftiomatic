import SwiftSyntax

/// Flag `@MainActor` on a type that conforms to `FileDocument` or `ReferenceFileDocument` .
///
/// SwiftUI calls `init(configuration:)` , `fileWrapper(configuration:)` and `snapshot(contentType:)`
/// of a document on a background queue. A main-actor type cannot satisfy these nonisolated
/// requirements. The compiler rejects the conformance, or the code hops to the main actor and
/// blocks the document queue.
///
/// Keep the document type nonisolated. Isolate the state that the user interface reads in a
/// separate `@MainActor` model.
///
/// The rule reads the conformances of the type declaration and of its extensions in the same file.
/// It also flags `@MainActor` on an extension that adds the conformance.
///
/// Lint: A type or extension that conforms to `FileDocument` or `ReferenceFileDocument` has the
/// attribute `@MainActor` .
final class NoMainActorOnFileDocument: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .mustNot }

    /// The document protocols of SwiftUI
    private static let documentProtocols: Set<String> = ["FileDocument", "ReferenceFileDocument"]

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        check(name: node.name.text, attributes: node.attributes, isExtension: false, in: node)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        check(name: node.name.text, attributes: node.attributes, isExtension: false, in: node)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        check(name: node.name.text, attributes: node.attributes, isExtension: false, in: node)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let name = node.extendedType.simpleName else { return .visitChildren }
        check(name: name, attributes: node.attributes, isExtension: true, in: node)
        return .visitChildren
    }

    private func check(
        name: String,
        attributes: AttributeListSyntax,
        isExtension: Bool,
        in decl: some DeclGroupSyntax
    ) {
        guard let mainActor = Self.mainActorAttribute(in: attributes) else { return }

        let ownConformances = decl.inheritanceClause?.inheritedTypes.compactMap(\.type.simpleName)
            ?? []
        var conformances = Set(ownConformances)

        // A type declaration also conforms through its extensions in the same file
        if !isExtension, let entry = context.typeMembers(around: decl).types[name] {
            conformances.formUnion(entry.conformances)
        }
        guard !conformances.isDisjoint(with: Self.documentProtocols) else { return }
        diagnose(.mainActorDocument(name), on: mainActor)
    }

    /// The `@MainActor` attribute in `attributes` , in its plain or qualified spelling
    private static func mainActorAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        for element in attributes {
            guard case let .attribute(attribute) = element,
                  attribute.attributeName.simpleName == "MainActor" else { continue }
            return attribute
        }
        return nil
    }
}

fileprivate extension Finding.Message {
    static func mainActorDocument(_ name: String) -> Finding.Message {
        "remove '@MainActor' from '\(name)'. SwiftUI reads and writes a document off the main actor"
    }
}
