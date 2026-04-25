import SwiftSyntax

/// Ensure all modifiers are on the same line as the declaration keyword.
///
/// Modifiers (not attributes) that appear on separate lines from the declaration keyword
/// are joined onto the same line. Attributes may remain on their own lines.
///
/// Lint: If any modifier is on a different line than the declaration keyword, a lint warning
/// is raised.
///
/// Format: Newlines between modifiers and the declaration keyword are replaced with spaces.
final class ModifiersOnSameLine: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .lineBreaks }

    // MARK: - Container declarations

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ClassDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.classKeyword))
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(StructDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.structKeyword))
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(EnumDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.enumKeyword))
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ActorDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.actorKeyword))
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ProtocolDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.protocolKeyword))
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ExtensionDeclSyntax.self)
        return DeclSyntax(collapseModifierLines(of: visited, keywordKeyPath: \.extensionKeyword))
    }

    // MARK: - Leaf declarations

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword))
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.bindingSpecifier))
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.initKeyword))
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.subscriptKeyword))
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.typealiasKeyword))
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.caseKeyword))
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.importKeyword))
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.deinitKeyword))
    }

    override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.associatedtypeKeyword))
    }

    // MARK: - Helper

    private func collapseModifierLines<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        of decl: Decl,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
    ) -> Decl {
        let modifiers = decl.modifiers
        guard !modifiers.isEmpty else { return decl }

        // Check if any modifier (after the first) or the keyword has a newline in its leading trivia.
        var needsFix = false
        for (index, modifier) in modifiers.enumerated() {
            if index == 0 { continue }
            if modifier.leadingTrivia.containsNewlines {
                needsFix = true
                break
            }
        }
        if decl[keyPath: keywordKeyPath].leadingTrivia.containsNewlines {
            needsFix = true
        }
        guard needsFix else { return decl }

        // If there are comments between modifiers, preserve existing formatting.
        for (index, modifier) in modifiers.enumerated() {
            if index == 0 { continue }
            if modifier.leadingTrivia.hasAnyComments { return decl }
        }
        if decl[keyPath: keywordKeyPath].leadingTrivia.hasAnyComments { return decl }

        diagnose(.modifiersNotOnSameLine, on: modifiers.first!)

        var result = decl
        var newModifiers = Array(modifiers)
        for i in 1..<newModifiers.count {
            if newModifiers[i].leadingTrivia.containsNewlines {
                newModifiers[i].leadingTrivia = .space
            }
        }
        result.modifiers = DeclModifierListSyntax(newModifiers)

        if result[keyPath: keywordKeyPath].leadingTrivia.containsNewlines {
            result[keyPath: keywordKeyPath].leadingTrivia = .space
        }

        return result
    }
}

extension Finding.Message {
    fileprivate static let modifiersNotOnSameLine: Finding.Message =
        "place all modifiers on the same line as the declaration keyword"
}
