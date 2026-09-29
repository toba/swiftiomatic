import SwiftSyntax

/// The members of every type one source file declares, keyed by the type's simple name.
///
/// A lint rule that has to know what a bare name inside a type refers to reads this index. The
/// rules that check SwiftUI update boundaries ask whether a name is a stored input, a `private let`
/// , a `static` member, a computed property or a method. `Context` builds one index per tree on
/// first use, so a file costs one walk however many rules read it.
///
/// A type and its extensions in the same file merge into one entry. Every key is a simple name, so
/// a nested type merges with a top-level type of the same name.
///
/// When the run has a `ProjectIndex` , a lookup also reads the other files of the project. The
/// type-level facts merge, and the members of the other files go into `foreignMembers` . The
/// `members` of an entry stay the members of this file, so a rule that walks them never reports
/// on another file.
struct TypeMemberIndex: Sendable {
    struct Member: Sendable {
        enum Kind { case storedProperty, computedProperty, method }

        let kind: Kind
        let isStatic: Bool
        /// `private` or `fileprivate`
        let isPrivate: Bool
        /// `let` rather than `var` , for a property
        let isLet: Bool
        /// The declaration the member comes from
        let declaration: DeclSyntax
        /// The code that runs when the member is read or called, or `nil` for a stored property
        let body: Syntax?
    }

    struct TypeEntry: Sendable {
        enum Kind: Sendable { case `struct`, `class`, `enum`, actor }

        /// The kind of the type declaration, or `nil` when the file holds only extensions of it
        var kind: Kind?
        /// Whether the type declaration carries the `@Observable` attribute
        var isObservable = false
        /// Whether the declaration or a same-file extension conforms to `View` or `ViewModifier`
        var isView = false
        /// The last names of the types that the declaration and its same-file extensions inherit
        var conformances: Set<String> = []
        /// Whether an enum declares a case with associated values
        var hasPayloadCases = false
        /// Members that this file declares, keyed by base name. Overloads share one key.
        var members: [String: [Member]] = [:]
        /// Members that other files of the project declare, keyed by base name. Their declarations
        /// belong to trees that `ProjectIndex` loaded.
        var foreignMembers: [String: [Member]] = [:]

        /// The members of this file and of other files, keyed by base name
        var allMembers: [String: [Member]] {
            foreignMembers.isEmpty ? members : members.merging(foreignMembers, uniquingKeysWith: +)
        }

        /// Every overload of `name` : the members of this file, then those of other files
        func members(named name: String) -> [Member]? {
            switch (members[name], foreignMembers[name]) {
                case (nil, nil): nil
                case let (local?, nil): local
                case let (nil, foreign?): foreign
                case let (local?, foreign?): local + foreign
            }
        }

        /// This entry with the facts and members of `foreign` , which other files hold
        func merging(_ foreign: TypeEntry) -> TypeEntry {
            var entry = self
            entry.kind = kind ?? foreign.kind
            entry.isObservable = isObservable || foreign.isObservable
            entry.isView = isView || foreign.isView
            entry.conformances.formUnion(foreign.conformances)
            entry.hasPayloadCases = hasPayloadCases || foreign.hasPayloadCases
            entry.foreignMembers = foreign.foreignMembers
            return entry
        }
    }

    /// The types by simple name: the entry of this file, merged with the facts of other files
    struct TypeTable: Sendable {
        /// The entries of this file alone
        let local: [String: TypeEntry]
        let lookup: ProjectLookup?

        subscript(name: String) -> TypeEntry? {
            let entry = local[name]
            guard let lookup,
                  let foreign = lookup.foreignEntry(named: name, localIsNominal: entry?.kind != nil)
            else { return entry }
            return (entry ?? TypeEntry()).merging(foreign)
        }
    }

    /// The typealias targets by simple name: those of this file, then one of another file
    struct TypeAliasTable: Sendable {
        /// The typealiases of this file alone
        let local: [String: TypeSyntax]
        let lookup: ProjectLookup?

        subscript(name: String) -> TypeSyntax? {
            local[name] ?? lookup?.foreignTypeAlias(named: name)
        }
    }

    /// The protocols that make a type a view for the SwiftUI boundary rules
    static let viewProtocols: Set<String> = [
        "View", "SwiftUI.View", "ViewModifier", "SwiftUI.ViewModifier",
    ]

    let types: TypeTable

    /// The target type of every typealias, keyed by the alias's simple name. A nested alias merges
    /// with a top-level alias of the same name.
    let typeAliases: TypeAliasTable

    /// The lookups into other files, or `nil` when the run has no project index
    let lookup: ProjectLookup?

    init(root: Syntax, lookup: ProjectLookup? = nil) {
        let collector = Collector(viewMode: .sourceAccurate)
        collector.walk(root)
        types = TypeTable(local: collector.types, lookup: lookup)
        typeAliases = TypeAliasTable(local: collector.typeAliases, lookup: lookup)
        self.lookup = lookup
    }

    /// The names of the project types whose member with the base name `member` names `Binding`
    func typesWithBindingMember(named member: String) -> [String] {
        lookup?.typesWithBindingMember(named: member) ?? []
    }

    /// The entry for the type whose member block holds `node`
    func enclosingType(of node: some SyntaxProtocol) -> TypeEntry? {
        Self.enclosingTypeName(of: node).flatMap { types[$0] }
    }

    /// The simple name of the innermost type or extension whose member block holds `node`
    static func enclosingTypeName(of node: some SyntaxProtocol) -> String? {
        owningDeclaration(of: node).flatMap(typeName(of:))
    }

    /// The innermost type, extension or protocol declaration whose member block holds `node`
    static func owningDeclaration(of node: some SyntaxProtocol) -> Syntax? {
        var current = node.parent

        while let cur = current {
            if cur.is(MemberBlockSyntax.self) { return cur.parent }
            current = cur.parent
        }
        return nil
    }

    /// The declaration that directly holds `member` , and every top-level declaration or extension
    /// of the type named `typeName` in the same file
    static func declarationRegions(
        ofMember member: some SyntaxProtocol,
        typeName: String
    ) -> [any DeclGroupSyntax] {
        var regions = member.root.as(SourceFileSyntax.self)?.statements.compactMap {
            item -> any DeclGroupSyntax? in
            guard let group = item.item.asProtocol((any DeclGroupSyntax).self),
                  Self.typeName(of: Syntax(group)) == typeName else { return nil }
            return group
        } ?? []

        // A nested type is not a top-level statement, so add its own declaration
        if let owner = owningDeclaration(of: member)?.asProtocol((any DeclGroupSyntax).self),
           !regions.contains(where: { $0.id == owner.id }) { regions.append(owner) }
        return regions
    }

    /// The simple name a type declaration or an extension declares or extends
    static func typeName(of decl: Syntax) -> String? {
        if let s = decl.as(StructDeclSyntax.self) { return s.name.text }
        if let c = decl.as(ClassDeclSyntax.self) { return c.name.text }
        if let e = decl.as(EnumDeclSyntax.self) { return e.name.text }
        if let a = decl.as(ActorDeclSyntax.self) { return a.name.text }

        if let ext = decl.as(ExtensionDeclSyntax.self) {
            if let member = ext.extendedType.as(MemberTypeSyntax.self) { return member.name.text }
            return ext.extendedType.as(IdentifierTypeSyntax.self)?.name.text
        }
        return nil
    }

    private final class Collector: SyntaxVisitor {
        var types: [String: TypeEntry] = [:]
        var typeAliases: [String: TypeSyntax] = [:]

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            typeAliases[node.name.text] = node.initializer.value
            return .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                Syntax(node),
                kind: .struct,
                attributes: node.attributes,
                inheritance: node.inheritanceClause,
                members: node.memberBlock
            )
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                Syntax(node),
                kind: .class,
                attributes: node.attributes,
                inheritance: node.inheritanceClause,
                members: node.memberBlock
            )
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                Syntax(node),
                kind: .enum,
                attributes: node.attributes,
                inheritance: node.inheritanceClause,
                members: node.memberBlock
            )
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            record(
                Syntax(node),
                kind: .actor,
                attributes: node.attributes,
                inheritance: node.inheritanceClause,
                members: node.memberBlock
            )
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), inheritance: node.inheritanceClause, members: node.memberBlock)
        }

        private func record(
            _ decl: Syntax,
            kind: TypeEntry.Kind? = nil,
            attributes: AttributeListSyntax? = nil,
            inheritance: InheritanceClauseSyntax?,
            members: MemberBlockSyntax
        ) -> SyntaxVisitorContinueKind {
            guard let name = TypeMemberIndex.typeName(of: decl) else { return .visitChildren }
            var entry = types[name] ?? TypeEntry()

            if let kind {
                entry.kind = kind
                entry.isObservable = attributes?.attribute(named: "Observable") != nil
            }

            if let inheritance {
                if inheritance.inheritedTypes.contains(where: {
                    TypeMemberIndex.viewProtocols.contains($0.type.trimmedDescription)
                }) { entry.isView = true }
                entry.conformances.formUnion(
                    inheritance.inheritedTypes.compactMap(\.type.simpleName))
            }

            if let enumDecl = decl.as(EnumDeclSyntax.self),
               enumDecl.memberBlock.members.contains(where: { item in
                   item.decl.as(EnumCaseDeclSyntax.self)?.elements
                       .contains { $0.parameterClause != nil } == true
               }) { entry.hasPayloadCases = true }

            for item in members.members {
                for (memberName, member) in Self.members(of: item.decl) {
                    entry.members[memberName, default: []].append(member)
                }
            }
            types[name] = entry
            return .visitChildren
        }

        private static func members(of decl: DeclSyntax) -> [(String, Member)] {
            if let variable = decl.as(VariableDeclSyntax.self) {
                let isStatic = variable.modifiers.contains { $0.isStaticOrClass }
                let isPrivate = variable.modifiers.contains { $0.isPrivateOrFileprivate }
                let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)

                return variable.bindings.flatMap { binding -> [(String, Member)] in
                    let body = binding.accessorBlock.flatMap(Self.getterBody)
                    let kind: Member.Kind = body == nil ? .storedProperty : .computedProperty
                    let member = Member(
                        kind: kind,
                        isStatic: isStatic,
                        isPrivate: isPrivate,
                        isLet: isLet,
                        declaration: decl,
                        body: body
                    )
                    return binding.pattern.boundIdentifierNames.map { ($0, member) }
                }
            }

            if let function = decl.as(FunctionDeclSyntax.self) {
                let member = Member(
                    kind: .method,
                    isStatic: function.modifiers.contains { $0.isStaticOrClass },
                    isPrivate: function.modifiers.contains { $0.isPrivateOrFileprivate },
                    isLet: false,
                    declaration: decl,
                    body: function.body.map(Syntax.init)
                )
                return [(function.name.text, member)]
            }
            return []
        }

        /// The code a read runs, or `nil` when the accessor block holds only observers
        private static func getterBody(_ block: AccessorBlockSyntax) -> Syntax? {
            switch block.accessors {
                case let .getter(statements): return Syntax(statements)
                case let .accessors(list):
                    let getter = list.first { $0.accessorSpecifier.tokenKind == .keyword(.get) }
                    return getter?.body.map(Syntax.init)
            }
        }
    }
}

// MARK: - Member references

extension TypeMemberIndex {
    /// One read of a same-type member inside a region of code
    struct Reference {
        let name: String
        /// The spelling in source, `$selection` for a projected binding
        let spelling: String
        /// Every overload the name reaches. A syntax-only rule cannot pick one, so a caller treats
        /// the read as touching them all.
        let members: [Member]
        let node: DeclReferenceExprSyntax
    }

    /// The reads of `entry` 's members inside `region` , in source order
    ///
    /// A bare name counts when no closure parameter, function parameter or earlier local binding
    /// between the read and the enclosing member declaration shadows it. `self.name` always counts.
    /// `Self.name` and `TypeName.name` never count, because the base names a type.
    ///
    /// - Parameter skipping: Returns `true` for a closure whose contents the caller ignores.
    static func references(
        in region: some SyntaxProtocol,
        of entry: TypeEntry,
        skipping: @escaping (ClosureExprSyntax) -> Bool = { _ in false }
    ) -> [Reference] {
        let finder = ReferenceFinder(entry: entry, skipping: skipping)
        finder.walk(region)
        return finder.references
    }

    private final class ReferenceFinder: SyntaxVisitor {
        let entry: TypeEntry
        let skipping: (ClosureExprSyntax) -> Bool
        var references: [Reference] = []

        init(entry: TypeEntry, skipping: @escaping (ClosureExprSyntax) -> Bool) {
            self.entry = entry
            self.skipping = skipping
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            skipping(node) ? .skipChildren : .visitChildren
        }

        override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
            let spelling = node.baseName.text
            // `_name` is wrapper storage only when no member is declared with that exact name
            let name = entry.members(named: spelling) == nil
                && (spelling.hasPrefix("$") || spelling.hasPrefix("_"))
                ? String(spelling.dropFirst())
                : spelling
            guard let members = entry.members(named: name) else { return .visitChildren }

            if node.parent?.is(KeyPathPropertyComponentSyntax.self) == true {
                return .visitChildren
            }

            if let access = node.parent?.as(MemberAccessExprSyntax.self),
               access.declName.id == node.id
            {
                // only `self.name` reads a member of this type
                guard let base = access.base?.as(DeclReferenceExprSyntax.self),
                      base.baseName.tokenKind == .keyword(.self) else { return .visitChildren }
            } else if isShadowed(name, at: node) { return .visitChildren }
            references.append(Reference(
                name: name, spelling: spelling, members: members, node: node))
            return .visitChildren
        }

        /// Whether a binding between `node` and its enclosing member declaration declares `name`
        private func isShadowed(_ name: String, at node: DeclReferenceExprSyntax) -> Bool {
            var child = Syntax(node)
            var current = node.parent

            while let cur = current {
                if cur.is(MemberBlockItemSyntax.self) { return false }

                if let closure = cur.as(ClosureExprSyntax.self),
                   closure.signature?.parameterNames.contains(name) == true { return true }

                if let function = cur.as(FunctionDeclSyntax.self),
                   function.signature.parameterClause.parameters.contains(where: {
                       ($0.secondName ?? $0.firstName).text == name
                   }) { return true }

                if let list = cur.as(CodeBlockItemListSyntax.self) {
                    for item in list where item.endPosition <= child.position {
                        if Self.declares(name, item: item) { return true }
                    }
                }

                if Self.conditionBinds(name, in: cur, around: child) { return true }
                child = cur
                current = cur.parent
            }
            return false
        }

        /// Whether a statement binds `name` for the statements after it
        private static func declares(_ name: String, item: CodeBlockItemSyntax) -> Bool {
            if let variable = item.item.as(VariableDeclSyntax.self) {
                return variable.bindings.contains { $0.pattern.boundIdentifierNames.contains(name) }
            }
            if let guardStmt = item.item.as(GuardStmtSyntax.self) {
                return guardStmt.conditions.bindsName(name)
            }
            return false
        }

        /// Whether `node` binds `name` for its body, which holds `child`
        private static func conditionBinds(
            _ name: String,
            in node: Syntax,
            around child: Syntax
        ) -> Bool {
            if let ifExpr = node.as(IfExprSyntax.self), child.id == ifExpr.body.id {
                return ifExpr.conditions.bindsName(name)
            }

            if let whileStmt = node.as(WhileStmtSyntax.self), child.id == whileStmt.body.id {
                return whileStmt.conditions.bindsName(name)
            }

            if let forStmt = node.as(ForStmtSyntax.self), child.id == forStmt.body.id {
                return forStmt.pattern.boundIdentifierNames.contains(name)
            }

            if let switchCase = node.as(SwitchCaseSyntax.self),
               child.id == switchCase.statements.id,
               case let .case(label) = switchCase.label {
                return label.caseItems.contains { $0.pattern.boundIdentifierNames.contains(name) }
            }
            return false
        }
    }
}

private extension DeclModifierSyntax {
    var isStaticOrClass: Bool {
        name.tokenKind == .keyword(.static) || name.tokenKind == .keyword(.class)
    }

    var isPrivateOrFileprivate: Bool {
        name.tokenKind == .keyword(.private) || name.tokenKind == .keyword(.fileprivate)
    }
}

private extension ConditionElementListSyntax {
    func bindsName(_ name: String) -> Bool {
        contains {
            guard case let .optionalBinding(binding) = $0.condition else { return false }
            return binding.pattern.boundIdentifierNames.contains(name)
        }
    }
}

extension ClosureSignatureSyntax {
    /// The names the closure binds for its parameters, in order
    ///
    /// A parameter spelled `label name` binds `name` .
    var parameterNames: [String] {
        switch parameterClause {
            case let .simpleInput(list): list.map(\.name.text)
            case let .parameterClause(clause):
                clause.parameters.map { ($0.secondName ?? $0.firstName).text }
            case nil: []
        }
    }
}

private extension SyntaxProtocol {
    /// The names every identifier pattern inside this node binds
    var boundIdentifierNames: [String] {
        if let identifier = Syntax(self).as(IdentifierPatternSyntax.self) {
            return [identifier.identifier.text]
        }
        return children(viewMode: .sourceAccurate).flatMap(\.boundIdentifierNames)
    }
}

// MARK: - Type names

extension TypeMemberIndex {
    /// The name token of the type that `declaration` declares or extends
    ///
    /// A type declaration gives its own name. An extension gives the name of the first struct,
    /// class, enum or actor declaration in the same file with the extended simple name. The result
    /// is `nil` when the file does not declare that type.
    static func typeNameToken(of declaration: Syntax) -> TokenSyntax? {
        if let name = declaration.asProtocol((any NamedDeclSyntax).self)?.name { return name }
        guard declaration.is(ExtensionDeclSyntax.self),
              let name = typeName(of: declaration) else { return nil }
        let finder = TypeNameFinder(name: name)
        finder.walk(declaration.root)
        return finder.token
    }

    /// Finds the name token of the first nominal type declaration with a given name
    private final class TypeNameFinder: SyntaxVisitor {
        let name: String
        var token: TokenSyntax?

        init(name: String) {
            self.name = name
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            match(node.name)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            match(node.name)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            match(node.name)
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            match(node.name)
        }

        override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        override func visit(_: VariableDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        private func match(_ candidate: TokenSyntax) -> SyntaxVisitorContinueKind {
            guard token == nil else { return .skipChildren }
            if candidate.text == name { token = candidate }
            return token == nil ? .visitChildren : .skipChildren
        }
    }
}

extension TypeMemberIndex.Member {
    /// The statements that run when the member is read or called, or `nil` for a stored property
    ///
    /// A getter written as a bare list of statements and a function or accessor body both give
    /// their statements.
    var statements: CodeBlockItemListSyntax? {
        if let list = body?.as(CodeBlockItemListSyntax.self) { return list }
        return body?.as(CodeBlockSyntax.self)?.statements
    }
}
