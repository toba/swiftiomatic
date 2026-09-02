import SwiftSyntax

/// What one source file declares, keyed by the simple name of each declaration.
///
/// A rule that has to answer a question about a name it meets reads this index instead of walking
/// the file again. Two such questions today are which protocol requirement a member witnesses, and
/// whether a generic constraint names a declaration that carries an `@_spi` grant. `Context` builds
/// one index per file on first use, so a file costs one walk however many rules read it.
///
/// Every key is a simple spelling, so a nested type merges with a top-level type of the same name.
/// A merge only adds facts, which makes a conservative reader more conservative rather than less.
struct FileDeclarationIndex {
    /// Names one requirement by its base name and its parameter count.
    ///
    /// An initializer requirement takes the name `init` .
    struct RequirementKey: Hashable {
        let name: String
        let parameterCount: Int
    }

    struct ProtocolEntry {
        /// Positions each requirement declares `@escaping` for
        var requirements: [RequirementKey: Set<Int>] = [:]
        /// The names in the protocol's own inheritance clause
        var inherited: [String] = []
    }

    /// The protocol declarations, keyed by name
    private(set) var protocols: [String: ProtocolEntry] = [:]

    /// Inherited names of every declaration and every extension, keyed by the declared name
    private(set) var conformances: [String: [String]] = [:]

    /// Names of the struct, class, enum and actor declarations
    private(set) var concreteTypes: Set<String> = []

    /// Every declared name, a protocol and a type alias included
    private(set) var declaredNames: Set<String> = []

    /// Names of the declarations that carry an `@_spi` grant
    private(set) var spiNames: Set<String> = []

    init(file: SourceFileSyntax) {
        let collector = Collector(viewMode: .sourceAccurate)
        collector.walk(file)
        protocols = collector.protocols
        conformances = collector.conformances
        concreteTypes = collector.concreteTypes
        declaredNames = collector.declaredNames
        spiNames = collector.spiNames
    }

    private final class Collector: SyntaxVisitor {
        var protocols: [String: ProtocolEntry] = [:]
        var conformances: [String: [String]] = [:]
        var concreteTypes: Set<String> = []
        var declaredNames: Set<String> = []
        var spiNames: Set<String> = []

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            record(node, inheritance: node.inheritanceClause, isConcrete: true)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            record(node, inheritance: node.inheritanceClause, isConcrete: true)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            record(node, inheritance: node.inheritanceClause, isConcrete: true)
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            record(node, inheritance: node.inheritanceClause, isConcrete: true)
        }

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            record(node, inheritance: nil, isConcrete: false)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            let name = node.name.text
            var entry = ProtocolEntry(inherited: names(of: node.inheritanceClause))

            for member in node.memberBlock.members {
                if let function = member.decl.as(FunctionDeclSyntax.self) {
                    entry.record(function.signature.parameterClause, as: function.name.text)
                } else if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                    entry.record(initializer.signature.parameterClause, as: "init")
                }
            }
            protocols[name] = entry
            return record(node, inheritance: node.inheritanceClause, isConcrete: false)
        }

        /// An extension adds conformances to the type it extends, and declares no name of its own.
        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let name = node.extendedType.simpleName { append(node.inheritanceClause, to: name) }
            return .visitChildren
        }

        @discardableResult
        private func record(
            _ decl: some NamedDeclSyntax & WithAttributesSyntax,
            inheritance: InheritanceClauseSyntax?,
            isConcrete: Bool
        ) -> SyntaxVisitorContinueKind {
            let name = decl.name.text
            declaredNames.insert(name)

            if isConcrete { concreteTypes.insert(name) }
            if decl.attributes.attribute(named: "_spi") != nil { spiNames.insert(name) }
            append(inheritance, to: name)
            return .visitChildren
        }

        private func append(_ inheritance: InheritanceClauseSyntax?, to name: String) {
            conformances[name, default: []].append(contentsOf: names(of: inheritance))
        }

        /// The inherited names, with an unreadable one kept as the empty string so it resolves to
        /// nothing. A reader that treats an unresolved name as unsafe then stays conservative.
        private func names(of clause: InheritanceClauseSyntax?) -> [String] {
            guard let clause else { return [] }
            return clause.inheritedTypes.map { $0.type.simpleName ?? "" }
        }
    }
}

fileprivate extension FileDeclarationIndex.ProtocolEntry {
    /// Record the `@escaping` positions of one requirement.
    ///
    /// Two requirements that share a name and a parameter count merge, which reports more protected
    /// positions rather than fewer.
    mutating func record(_ clause: FunctionParameterClauseSyntax, as name: String) {
        var positions: Set<Int> = []

        for (position, parameter) in clause.parameters.enumerated() {
            guard let attributed = parameter.type.as(AttributedTypeSyntax.self),
                attributed.attributes.attribute(named: "escaping") != nil else { continue }
            positions.insert(position)
        }
        guard !positions.isEmpty else { return }
        let key = FileDeclarationIndex.RequirementKey(
            name: name, parameterCount: clause.parameters.count)
        requirements[key, default: []].formUnion(positions)
    }
}
