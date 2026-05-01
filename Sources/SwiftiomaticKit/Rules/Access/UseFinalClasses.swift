import SwiftSyntax

/// Prefer `final class` unless a class is designed for subclassing.
///
/// Classes should be `final` by default to communicate that they are not designed to be subclassed.
/// Classes are left non-final if they are `open` , have "Base" in the name, have a comment
/// mentioning "base" or "subclass", or are subclassed within the same file.
///
/// When a class is made `final` , any `open` members are converted to `public` since `final`
/// classes cannot have `open` members.
///
/// Lint: A non-final, non-open class declaration raises a warning.
///
/// Rewrite: The `final` modifier is added and `open` members are converted to `public` .
final class UseFinalClasses: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var subclassedNames: Set<String> = []
    }

    // MARK: - Compact-pipeline scope hooks

    /// Pre-scan the file for class names that appear in inheritance clauses, so a later `ClassDecl`
    /// visit can leave those classes non-final.
    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.useFinalClassesState
        collectSubclassedNamesRecursive(in: Syntax(node), into: &state.subclassedNames)
    }

    static func transform(
        _ node: ClassDeclSyntax,
        original _: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        if node.modifiers.contains(.final) { return DeclSyntax(node) }
        if node.modifiers.contains(.open) { return DeclSyntax(node) }
        if node.name.text.contains("Base") { return DeclSyntax(node) }
        if commentMentionsSubclassing(node) { return DeclSyntax(node) }

        let state = context.useFinalClassesState
        if state.subclassedNames.contains(node.name.text) { return DeclSyntax(node) }

        Self.diagnose(.useFinalClass, on: node.classKeyword, context: context)

        var result = node
        var finalModifier = DeclModifierSyntax(name: .keyword(.final, trailingTrivia: .space))

        if result.modifiers.isEmpty {
            finalModifier.leadingTrivia = result.classKeyword.leadingTrivia
            result.classKeyword.leadingTrivia = []
        }

        result.modifiers.append(finalModifier)
        result.memberBlock.members = convertOpenToPublic(in: result.memberBlock.members)

        return DeclSyntax(result)
    }

    private static func collectSubclassedNamesRecursive(
        in node: Syntax,
        into names: inout Set<String>
    ) {
        if let classDecl = node.as(ClassDeclSyntax.self),
           let inheritanceClause = classDecl.inheritanceClause
        {
            for inherited in inheritanceClause.inheritedTypes {
                if let identType = inherited.type.as(IdentifierTypeSyntax.self) {
                    names.insert(identType.name.text)
                }
            }
        }
        for child in node.children(viewMode: .sourceAccurate) {
            collectSubclassedNamesRecursive(in: child, into: &names)
        }
    }

    private static func commentMentionsSubclassing(_ node: ClassDeclSyntax) -> Bool {
        let text = node.leadingTrivia.pieces
            .compactMap { piece -> String? in
                switch piece {
                    case let .docLineComment(text),
                         let .docBlockComment(text),
                         let .lineComment(text),
                         let .blockComment(text):
                        text
                    default: nil
                }
            }
            .joined()
            .lowercased()

        return text.contains("base") || text.contains("subclass")
    }

    private static func convertOpenToPublic(
        in members: MemberBlockItemListSyntax
    ) -> MemberBlockItemListSyntax {
        MemberBlockItemListSyntax(
            members.map { member in
                guard let modified = replaceOpenModifier(in: member.decl) else { return member }
                var result = member
                result.decl = modified
                return result
            })
    }

    private static func replaceOpenModifier(in decl: DeclSyntax) -> DeclSyntax? {
        if var funcDecl = decl.as(FunctionDeclSyntax.self),
           let modifiers = openToPublic(funcDecl.modifiers)
        {
            funcDecl.modifiers = modifiers
            return DeclSyntax(funcDecl)
        }
        if var varDecl = decl.as(VariableDeclSyntax.self),
           let modifiers = openToPublic(varDecl.modifiers)
        {
            varDecl.modifiers = modifiers
            return DeclSyntax(varDecl)
        }
        if var subscriptDecl = decl.as(SubscriptDeclSyntax.self),
           let modifiers = openToPublic(subscriptDecl.modifiers)
        {
            subscriptDecl.modifiers = modifiers
            return DeclSyntax(subscriptDecl)
        }
        if var initDecl = decl.as(InitializerDeclSyntax.self),
           let modifiers = openToPublic(initDecl.modifiers)
        {
            initDecl.modifiers = modifiers
            return DeclSyntax(initDecl)
        }
        if var typeAliasDecl = decl.as(TypeAliasDeclSyntax.self),
           let modifiers = openToPublic(typeAliasDecl.modifiers)
        {
            typeAliasDecl.modifiers = modifiers
            return DeclSyntax(typeAliasDecl)
        }
        return nil
    }

    private static func openToPublic(
        _ modifiers: DeclModifierListSyntax
    ) -> DeclModifierListSyntax? {
        guard modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) else {
            return nil
        }
        return DeclModifierListSyntax(
            modifiers.map { mod in
                guard mod.name.tokenKind == .keyword(.open) else { return mod }
                return mod.with(
                    \.name,
                    .keyword(
                        .public,
                        leadingTrivia: mod.name.leadingTrivia,
                        trailingTrivia: mod.name.trailingTrivia
                    ))
            })
    }
}

fileprivate extension Finding.Message {
    static let useFinalClass: Finding.Message =
        "prefer 'final class' unless designed for subclassing"
}
