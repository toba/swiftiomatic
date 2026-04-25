import SwiftSyntax

/// Prefer `final class` unless a class is designed for subclassing.
///
/// Classes should be `final` by default to communicate that they are not designed to be
/// subclassed. Classes are left non-final if they are `open`, have "Base" in the name,
/// have a comment mentioning "base" or "subclass", or are subclassed within the same file.
///
/// When a class is made `final`, any `open` members are converted to `public` since
/// `final` classes cannot have `open` members.
///
/// Lint: A non-final, non-open class declaration raises a warning.
///
/// Format: The `final` modifier is added and `open` members are converted to `public`.
final class PreferFinalClasses: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

    /// Class names that appear as a superclass in some class declaration within the file.
    ///
    /// **Lifecycle**: per-file. Reset (overwritten) at the top of `visit(_:SourceFileSyntax)`,
    /// which is always the visitor's first call. Rule instances are constructed per-file by
    /// the pipeline, so this state cannot leak across files in the current architecture; the
    /// reset in `visit(_:SourceFileSyntax)` keeps the invariant explicit if a future caller
    /// reuses an instance.
    private var subclassedNames = Set<String>()

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        subclassedNames = collectSubclassedNames(in: Syntax(node))
        return super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ClassDeclSyntax.self)

        // Already final
        if visited.modifiers.contains(.final) {
            return DeclSyntax(visited)
        }

        // Open classes are designed for subclassing
        if visited.modifiers.contains(.open) {
            return DeclSyntax(visited)
        }

        // Name contains "Base" — convention for base classes
        if visited.name.text.contains("Base") { return DeclSyntax(visited) }

        // Comment mentions base class or subclassing
        if commentMentionsSubclassing(node) { return DeclSyntax(visited) }

        // Class is subclassed within this file
        if subclassedNames.contains(visited.name.text) { return DeclSyntax(visited) }

        diagnose(.preferFinalClass, on: visited.classKeyword)

        var result = visited

        // Add `final` modifier
        var finalModifier = DeclModifierSyntax(
            name: .keyword(.final, trailingTrivia: .space))

        if result.modifiers.isEmpty {
            finalModifier.leadingTrivia = result.classKeyword.leadingTrivia
            result.classKeyword.leadingTrivia = []
        }

        result.modifiers.append(finalModifier)

        // Convert `open` members to `public` (final classes can't have open members)
        result.memberBlock.members = convertOpenToPublic(in: result.memberBlock.members)

        return DeclSyntax(result)
    }

    // MARK: - Subclass detection

    /// Scans the syntax tree for class declarations and collects names used in inheritance clauses.
    private func collectSubclassedNames(in node: Syntax) -> Set<String> {
        var names = Set<String>()
        collectSubclassedNamesRecursive(in: node, into: &names)
        return names
    }

    private func collectSubclassedNamesRecursive(in node: Syntax, into names: inout Set<String>) {
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

    // MARK: - Doc comment detection

    /// Returns true if any comment in the leading trivia mentions "base" or "subclass".
    private func commentMentionsSubclassing(_ node: ClassDeclSyntax) -> Bool {
        let text = node.leadingTrivia.pieces
            .compactMap { piece -> String? in
                switch piece {
                    case .docLineComment(let text), .docBlockComment(let text),
                        .lineComment(let text),
                        .blockComment(let text):
                        text
                    default: nil
                }
            }
            .joined()
            .lowercased()

        return text.contains("base") || text.contains("subclass")
    }

    // MARK: - Open → public conversion

    /// Replaces `open` modifiers with `public` on direct members of a class.
    private func convertOpenToPublic(
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

    private func replaceOpenModifier(in decl: DeclSyntax) -> DeclSyntax? {
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

    /// Returns a new modifier list with `open` replaced by `public`, or nil if no change needed.
    private func openToPublic(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax? {
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

extension Finding.Message {
    fileprivate static let preferFinalClass: Finding.Message =
        "prefer 'final class' unless designed for subclassing"
}
