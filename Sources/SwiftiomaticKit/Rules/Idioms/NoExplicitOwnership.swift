import SwiftSyntax

/// Remove explicit `borrowing` and `consuming` ownership modifiers.
///
/// Ownership modifiers are an advanced feature that most code does not need. When present on
/// function declarations (e.g. `consuming func move()` ) or parameter types (e.g.
/// `func foo(_ bar: consuming Bar)` ), they are removed.
///
/// Lint: If an explicit `borrowing` or `consuming` modifier is found, a lint warning is raised.
///
/// Rewrite: The ownership modifier is removed.
final class NoExplicitOwnership: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    private static let ownershipKeywords: Set<Keyword> = [.borrowing, .consuming]

    // MARK: - Declaration modifiers (e.g. `consuming func move()`)

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard let concrete = visited.as(FunctionDeclSyntax.self) else { return visited }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ visited: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(
            removingOwnershipModifier(
                from: visited,
                keywordKeyPath: \.funcKeyword,
                context: context
            )
        )
    }

    // MARK: - Type specifiers (e.g. `consuming Foo` in parameter types)

    override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard let concrete = visited.as(AttributedTypeSyntax.self) else { return visited }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ attributed: AttributedTypeSyntax,
        parent: Syntax?,
        context: Context
    ) -> TypeSyntax {
        let ownershipIndices = attributed.specifiers.enumerated().compactMap {
            index, element -> Int? in
            guard case let .simpleTypeSpecifier(simple) = element,
                  case let .keyword(kw) = simple.specifier.tokenKind,
                  Self.ownershipKeywords.contains(kw) else { return nil }
            return index
        }
        guard !ownershipIndices.isEmpty else { return TypeSyntax(attributed) }

        // Diagnose each ownership specifier.
        for index in ownershipIndices {
            if case let .simpleTypeSpecifier(simple) = attributed.specifiers[
                attributed.specifiers.index(attributed.specifiers.startIndex, offsetBy: index)
            ] {
                Self.diagnose(
                    .removeOwnershipModifier(keyword: simple.specifier.text),
                    on: simple.specifier,
                    context: context
                )
            }
        }

        // Remove ownership specifiers.
        let ownershipSet = Set(ownershipIndices)
        let remaining = attributed.specifiers.enumerated().filter {
            !ownershipSet.contains($0.offset)
        }
        .map(\.element)

        // If nothing remains besides the base type, unwrap.
        if remaining.isEmpty, attributed.attributes.isEmpty, attributed.lateSpecifiers.isEmpty {
            var base = attributed.baseType
            base.leadingTrivia = attributed.leadingTrivia
            base.trailingTrivia = attributed.trailingTrivia
            return TypeSyntax(base)
        }

        var result = attributed
        result.specifiers = TypeSpecifierListSyntax(remaining)
        return TypeSyntax(result)
    }

    // MARK: - Helper

    private static func removingOwnershipModifier<
        Decl: DeclSyntaxProtocol & WithModifiersSyntax
    >(
        from decl: Decl,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let ownershipModifier = decl.modifiers.first(where: { modifier in
            guard case let .keyword(kw) = modifier.name.tokenKind else { return false }
            return Self.ownershipKeywords.contains(kw)
        }) else { return decl }

        Self.diagnose(
            .removeOwnershipModifier(keyword: ownershipModifier.name.text),
            on: ownershipModifier.name,
            context: context
        )

        return decl.removingModifiers(Self.ownershipKeywords, keyword: keywordKeyPath)
    }
}

fileprivate extension Finding.Message {
    static func removeOwnershipModifier(keyword: String) -> Finding.Message {
        "remove explicit '\(keyword)' ownership modifier"
    }
}
