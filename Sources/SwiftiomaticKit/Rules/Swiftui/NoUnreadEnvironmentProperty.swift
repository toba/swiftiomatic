import SwiftSyntax

/// Flag an `@Environment` or `@FocusedValue` property of a view that no member of the view reads.
///
/// The declaration is the subscription. SwiftUI re-evaluates the view on every change to the value,
/// even when no code reads it. A property that no member reads costs updates and gives nothing
/// back.
///
/// A read is a reference to the name, to `self.name` , or to `$name` in any member of the type or
/// of a same-file extension of the type. A reference inside a nested type does not count. A local
/// binding that shadows the name does not count.
///
/// The rule checks one file at a time. An extension in another file can read a property that is not
/// `private` or `fileprivate` . Thus the rule reports only a `private` or `fileprivate` property,
/// or a property of a type that is `private` or `fileprivate` or that is nested in such a type.
///
/// Lint: A private `@Environment` or `@FocusedValue` property of a `View` or `ViewModifier` type
/// has no read in the file.
final class NoUnreadEnvironmentProperty: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    /// The wrappers that subscribe the view to a value that SwiftUI supplies
    private static let subscribingWrappers: Set<String> = ["Environment", "FocusedValue"]

    /// The member names that each type reads, keyed by the simple type name
    private var readNamesByType: [String: Set<String>] = [:]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let wrapper = node.attributes.firstAttributeName,
              Self.subscribingWrappers.contains(wrapper) else { return .visitChildren }
        guard !node.modifiers.contains(where: { $0.isStaticOrClass }),
              let entry = context.viewEntry(forMember: node),
              let owner = Self.owningTypeDecl(of: node),
              let typeName = TypeMemberIndex.typeName(of: owner) else { return .skipChildren }
        guard node.modifiers.contains(where: { $0.isPrivateOrFileprivate })
            || Self.isInPrivateType(owner)
        else { return .skipChildren }
        let reads = readNames(of: typeName, entry: entry, root: Syntax(node.root))

        for binding in node.bindings {
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  !reads.contains(name) else { continue }
            diagnose(
                .unreadSubscription(name),
                on: node,
                notes: [
                    Finding.Note(
                        message: .subscribingType(typeName),
                        location: Self.nameToken(of: owner).map {
                            Finding.Location($0.startLocation(
                                converter: context.sourceLocationConverter))
                        },
                        role: .owner
                    )
                ]
            )
        }
        return .skipChildren
    }

    /// The names of `entry` 's members that the type reads, across all its same-file declarations
    private func readNames(
        of typeName: String,
        entry: TypeMemberIndex.TypeEntry,
        root: Syntax
    ) -> Set<String> {
        if let cached = readNamesByType[typeName] { return cached }
        let collector = DeclarationCollector(typeName: typeName)
        collector.walk(root)
        var names = Set<String>()

        for block in collector.memberBlocks {
            for reference in TypeMemberIndex.references(in: block, of: entry)
                where Self.isOwnMember(reference.node, of: block)
            { names.insert(reference.name) }
        }
        readNamesByType[typeName] = names
        return names
    }

    /// Whether the innermost member block that holds `node` is `block` itself
    private static func isOwnMember(
        _ node: some SyntaxProtocol,
        of block: MemberBlockSyntax
    ) -> Bool {
        var current = node.parent

        while let cur = current {
            if cur.is(MemberBlockSyntax.self) { return cur.id == block.id }
            current = cur.parent
        }
        return false
    }

    /// The type declaration whose member block directly holds `node`
    private static func owningTypeDecl(of node: some SyntaxProtocol) -> Syntax? {
        guard let block = node.parent?.parent?.parent, block.is(MemberBlockSyntax.self)
        else { return nil }
        return block.parent
    }

    /// Whether `decl` or a type that holds it is `private` or `fileprivate`
    private static func isInPrivateType(_ decl: Syntax) -> Bool {
        var current: Syntax? = decl

        while let cur = current {
            if let group = cur.asProtocol(DeclGroupSyntax.self),
               group.modifiers.contains(where: { $0.isPrivateOrFileprivate }) { return true }
            current = cur.parent
        }
        return false
    }

    /// The name token of a type declaration
    private static func nameToken(of decl: Syntax) -> TokenSyntax? {
        if let s = decl.as(StructDeclSyntax.self) { return s.name }
        if let c = decl.as(ClassDeclSyntax.self) { return c.name }
        if let e = decl.as(EnumDeclSyntax.self) { return e.name }
        return decl.as(ActorDeclSyntax.self)?.name
    }

    /// Collects the member blocks of every declaration and extension of one type
    private final class DeclarationCollector: SyntaxVisitor {
        let typeName: String
        var memberBlocks: [MemberBlockSyntax] = []

        init(typeName: String) {
            self.typeName = typeName
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
            if let owner = node.parent, TypeMemberIndex.typeName(of: owner) == typeName {
                memberBlocks.append(node)
            }
            return .visitChildren
        }
    }
}

private extension DeclModifierSyntax {
    var isStaticOrClass: Bool {
        name.tokenKind == .keyword(.static) || name.tokenKind == .keyword(.class)
    }

    var isPrivateOrFileprivate: Bool {
        detail == nil
            && (name.tokenKind == .keyword(.private) || name.tokenKind == .keyword(.fileprivate))
    }
}

fileprivate extension Finding.Message {
    static func unreadSubscription(_ name: String) -> Finding.Message {
        "no member reads '\(name)'. The view still updates on every change to the value. Remove the property"
    }

    static func subscribingType(_ name: String) -> Finding.Message {
        "'\(name)' subscribes to the value here"
    }
}
