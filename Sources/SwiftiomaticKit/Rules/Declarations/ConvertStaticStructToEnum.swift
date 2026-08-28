import SwiftSyntax

/// Convert types hosting only static members into enums.
///
/// An empty enum is the canonical way to create a namespace in Swift because it cannot be
/// instantiated. Structs and classes that contain only static members serve the same purpose but
/// can be accidentally instantiated.
///
/// This rule skips types with inheritance clauses, attributes, generic parameters, initializers, or
/// any instance members.
///
/// Lint: A struct or final class containing only static members raises a warning.
///
/// Rewrite: The `struct` or `final class` keyword is replaced with `enum` .
final class ConvertStaticStructToEnum: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 1190

    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ visited: StructDeclSyntax,
        original: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isLocalDeclaration(original) else { return DeclSyntax(visited) }
        guard shouldBeEnum(
            attributes: visited.attributes,
            inheritanceClause: visited.inheritanceClause,
            genericParameterClause: visited.genericParameterClause,
            genericWhereClause: visited.genericWhereClause,
            members: visited.memberBlock.members
        ) else { return DeclSyntax(visited) }

        // Diagnose against the original (pre-rewrite) name so the source location
        // resolves through the file's `SourceLocationConverter` correctly.
        // `visited` is detached from the source tree once children have been rewritten.
        Self.diagnose(.useEnumNamespace, on: original.name, context: context)

        let enumDecl = EnumDeclSyntax(
            modifiers: visited.modifiers,
            enumKeyword: .keyword(
                .enum,
                leadingTrivia: visited.structKeyword.leadingTrivia,
                trailingTrivia: visited.structKeyword.trailingTrivia
            ),
            name: visited.name,
            memberBlock: visited.memberBlock
        )
        return DeclSyntax(enumDecl)
    }

    static func transform(
        _ visited: ClassDeclSyntax,
        original: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isLocalDeclaration(original) else { return DeclSyntax(visited) }
        // Only final classes can be converted — non-final classes might be subclassed
        let isFinal = visited.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
        guard isFinal else { return DeclSyntax(visited) }

        guard shouldBeEnum(
            attributes: visited.attributes,
            inheritanceClause: visited.inheritanceClause,
            genericParameterClause: visited.genericParameterClause,
            genericWhereClause: visited.genericWhereClause,
            members: visited.memberBlock.members
        ) else { return DeclSyntax(visited) }

        Self.diagnose(.useEnumNamespace, on: original.name, context: context)

        // Remove the `final` modifier, transferring its trivia to the enum keyword
        let modifiers = DeclModifierListSyntax(
            visited.modifiers.lazy.filter { $0.name.tokenKind != .keyword(.final) }
        )

        let enumDecl = EnumDeclSyntax(
            modifiers: modifiers,
            enumKeyword: .keyword(
                .enum,
                leadingTrivia: visited.leadingTrivia,
                trailingTrivia: visited.classKeyword.trailingTrivia
            ),
            name: visited.name,
            memberBlock: visited.memberBlock
        )
        return DeclSyntax(enumDecl)
    }

    private static func shouldBeEnum(
        attributes: AttributeListSyntax,
        inheritanceClause: InheritanceClauseSyntax?,
        genericParameterClause: GenericParameterClauseSyntax?,
        genericWhereClause: GenericWhereClauseSyntax?,
        members: MemberBlockItemListSyntax
    ) -> Bool {
        guard attributes.isEmpty else { return false }
        guard inheritanceClause == nil else { return false }
        guard genericParameterClause == nil, genericWhereClause == nil else { return false }
        guard !members.isEmpty else { return false }
        return members.allSatisfy { hostsOnlyStaticContent($0.decl) }
    }

    private static func hostsOnlyStaticContent(_ decl: DeclSyntax) -> Bool {
        if decl.is(StructDeclSyntax.self) || decl.is(ClassDeclSyntax.self)
            || decl.is(EnumDeclSyntax.self) || decl.is(ActorDeclSyntax.self)
            || decl.is(ProtocolDeclSyntax.self) || decl.is(TypeAliasDeclSyntax.self)
        {
            return true
        }
        if decl.is(InitializerDeclSyntax.self) { return false }
        if let varDecl = decl.as(VariableDeclSyntax.self) {
            // Any attribute on a member could be a macro that synthesizes instance
            // behavior on the host type (e.g. `@Test`, `@Observable`-style peers) —
            // be conservative and don't rewrite.
            if !varDecl.attributes.isEmpty { return false }
            return hasStaticModifier(varDecl.modifiers)
        }
        if let funcDecl = decl.as(FunctionDeclSyntax.self) {
            if !funcDecl.attributes.isEmpty { return false }
            return hasStaticModifier(funcDecl.modifiers)
        }
        if let subDecl = decl.as(SubscriptDeclSyntax.self) {
            if !subDecl.attributes.isEmpty { return false }
            return hasStaticModifier(subDecl.modifiers)
        }

        if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
            return ifConfig.clauses.allSatisfy { clause in
                guard let elements = clause.elements?.as(MemberBlockItemListSyntax.self) else {
                    return true
                }
                return elements.allSatisfy { hostsOnlyStaticContent($0.decl) }
            }
        }
        return true
    }

    private static func hasStaticModifier(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(.static) }
    }

    /// Returns `true` when the declaration sits inside a function/closure/accessor
    /// body (i.e. a `CodeBlockSyntax`). Local types are typically one-off fixtures
    /// — for example, the empty struct shapes inside swift-testing `@Test` method
    /// bodies that exist purely to exercise dump/diff output. Rewriting those to
    /// `enum` would change the test's semantics, so leave local declarations alone.
    private static func isLocalDeclaration(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = node.parent
        while let n = current {
            if n.is(CodeBlockSyntax.self) { return true }
            current = n.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let useEnumNamespace: Finding.Message =
        "use 'enum' instead of 'struct' or 'class' for types with only static members"
}
