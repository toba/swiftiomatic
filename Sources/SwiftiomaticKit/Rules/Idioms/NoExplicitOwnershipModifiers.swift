import Foundation
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
///
/// The rule keeps a modifier that the compiler requires or that changes the meaning of
/// noncopyable code. It keeps a parameter modifier when the parameter type names a type that this
/// file declares `~Copyable` or `~Escapable` , a generic parameter that an enclosing declaration
/// constrains with `~Copyable` or `~Escapable` , a type in the `Span` family, or a suppressed
/// conformance such as `some P & ~Copyable` . It keeps a method modifier inside a type that
/// suppresses `Copyable` or `Escapable` , and inside an extension of such a type. The rule cannot
/// see a type that another file declares.
final class NoExplicitOwnershipModifiers: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 390

    override class var group: ConfigurationGroup? { .idioms }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    private static let ownershipKeywords: Set<Keyword> = [.borrowing, .consuming]

    /// Standard library types that are `~Escapable` , where an ownership modifier is part of the
    /// lifetime contract.
    private static let spanFamilyNames: Set<String> = [
        "Span", "MutableSpan", "RawSpan", "MutableRawSpan", "OutputSpan", "OutputRawSpan",
        "UTF8Span",
    ]

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        /// The names of the types that this file declares `~Copyable` or `~Escapable` .
        var suppressedTypeNames: Set<String> = []
        /// Whether the pre-scan has run for this file.
        var analyzed = false
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.noExplicitOwnershipModifiersState
        guard !state.analyzed else { return }
        state.analyzed = true
        let collector = SuppressedTypeCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        state.suppressedTypeNames = collector.names
    }

    // MARK: - Declaration modifiers (e.g. `consuming func move()`)

    static func transform(
        _ visited: FunctionDeclSyntax,
        original: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isInsideSuppressedType(Syntax(original), context: context) else {
            return DeclSyntax(visited)
        }
        return DeclSyntax(removingOwnershipModifier(
            from: visited, keywordKeyPath: \.funcKeyword, context: context))
    }

    // MARK: - Type specifiers (e.g. `consuming Foo` in parameter types)

    static func transform(
        _ attributed: AttributedTypeSyntax,
        original: AttributedTypeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TypeSyntax {
        guard !requiresOwnership(original, context: context) else {
            return TypeSyntax(attributed)
        }
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
            if case let .simpleTypeSpecifier(simple) = attributed.specifiers[attributed.specifiers
                    .index(attributed.specifiers.startIndex, offsetBy: index)]
            {
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

    // MARK: - Noncopyable detection

    /// Whether the base type of `original` is noncopyable or nonescapable, as far as this file
    /// shows.
    private static func requiresOwnership(
        _ original: AttributedTypeSyntax,
        context: Context
    ) -> Bool {
        let baseType = original.baseType
        if containsSuppressedType(baseType) { return true }
        let names = context.noExplicitOwnershipModifiersState.suppressedTypeNames
            .union(suppressedGenericNames(around: Syntax(original)))
        return baseType.tokens(viewMode: .sourceAccurate).contains { token in
            guard case let .identifier(name) = token.tokenKind else {
                return token.tokenKind == .keyword(.Self) && names.contains("Self")
            }
            return names.contains(name) || spanFamilyNames.contains(name)
        }
    }

    /// Whether `node` sits in a type, a protocol or an extension whose type suppresses `Copyable`
    /// or `Escapable` .
    private static func isInsideSuppressedType(_ node: Syntax, context: Context) -> Bool {
        let names = context.noExplicitOwnershipModifiersState.suppressedTypeNames
        var current = node.parent
        while let ancestor = current {
            if let group = ancestor.asProtocol((any DeclGroupSyntax).self) {
                if let ext = group.as(ExtensionDeclSyntax.self) {
                    let extended = ext.extendedType.trimmedDescription
                    let simpleName = extended.split(separator: ".").last.map(String.init) ?? extended
                    return names.contains(simpleName)
                }
                return group.inheritanceClause.map(containsSuppressedType) ?? false
            }
            current = ancestor.parent
        }
        return false
    }

    /// The generic parameter names that an enclosing declaration constrains with `~Copyable` or
    /// `~Escapable` . Adds `Self` inside a type that suppresses either protocol.
    private static func suppressedGenericNames(around node: Syntax) -> Set<String> {
        var names = Set<String>()
        var current = node.parent
        while let ancestor = current {
            if let clause = ancestor.asProtocol((any WithGenericParametersSyntax).self)?
                .genericParameterClause
            {
                for parameter in clause.parameters
                    where parameter.inheritedType.map(containsSuppressedType) ?? false
                {
                    names.insert(parameter.name.text)
                }
            }
            if let whereClause = genericWhereClause(of: ancestor) {
                for requirement in whereClause.requirements {
                    guard case let .conformanceRequirement(conformance) = requirement.requirement,
                          containsSuppressedType(conformance.rightType) else { continue }
                    names.insert(conformance.leftType.trimmedDescription)
                }
            }
            if let group = ancestor.asProtocol((any DeclGroupSyntax).self),
               group.inheritanceClause.map(containsSuppressedType) ?? false
            {
                names.insert("Self")
            }
            current = ancestor.parent
        }
        return names
    }

    private static func genericWhereClause(of node: Syntax) -> GenericWhereClauseSyntax? {
        switch node.as(SyntaxEnum.self) {
            case let .functionDecl(decl): decl.genericWhereClause
            case let .initializerDecl(decl): decl.genericWhereClause
            case let .subscriptDecl(decl): decl.genericWhereClause
            case let .structDecl(decl): decl.genericWhereClause
            case let .enumDecl(decl): decl.genericWhereClause
            case let .classDecl(decl): decl.genericWhereClause
            case let .actorDecl(decl): decl.genericWhereClause
            case let .extensionDecl(decl): decl.genericWhereClause
            default: nil
        }
    }

    fileprivate static func containsSuppressedType(_ node: some SyntaxProtocol) -> Bool {
        if node.is(SuppressedTypeSyntax.self) { return true }
        return node.children(viewMode: .sourceAccurate).contains { containsSuppressedType($0) }
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

/// Collects the names of the types that a file declares `~Copyable` or `~Escapable` .
private final class SuppressedTypeCollector: SyntaxVisitor {
    var names = Set<String>()

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        record(node.name, node.inheritanceClause)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        record(node.name, node.inheritanceClause)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        record(node.name, node.inheritanceClause)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        record(node.name, node.inheritanceClause)
    }

    private func record(
        _ name: TokenSyntax,
        _ clause: InheritanceClauseSyntax?
    ) -> SyntaxVisitorContinueKind {
        if let clause, NoExplicitOwnershipModifiers.containsSuppressedType(clause) {
            names.insert(name.text)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func removeOwnershipModifier(keyword: String) -> Finding.Message {
        "remove explicit '\(keyword)' ownership modifier"
    }
}
