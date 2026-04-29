import SwiftSyntax

/// Ensure all modifiers are on the same line as the declaration keyword.
///
/// Modifiers (not attributes) that appear on separate lines from the declaration keyword
/// are joined onto the same line. Attributes may remain on their own lines.
///
/// Lint: If any modifier is on a different line than the declaration keyword, a lint warning
/// is raised.
///
/// Rewrite: Newlines between modifiers and the declaration keyword are replaced with spaces.
final class ModifiersOnSameLine: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .lineBreaks }

    // MARK: - Container declarations

    static func transform(
        _ node: ClassDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.classKeyword, context: context))
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.structKeyword, context: context))
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.enumKeyword, context: context))
    }

    static func transform(
        _ node: ActorDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.actorKeyword, context: context))
    }

    static func transform(
        _ node: ProtocolDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.protocolKeyword, context: context))
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.extensionKeyword, context: context))
    }

    // MARK: - Leaf declarations

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword, context: context))
    }

    static func transform(
        _ node: VariableDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.bindingSpecifier, context: context))
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.initKeyword, context: context))
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.subscriptKeyword, context: context))
    }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.typealiasKeyword, context: context))
    }

    static func transform(
        _ node: EnumCaseDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.caseKeyword, context: context))
    }

    static func transform(
        _ node: ImportDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.importKeyword, context: context))
    }

    static func transform(
        _ node: DeinitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.deinitKeyword, context: context))
    }

    static func transform(
        _ node: AssociatedTypeDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.associatedtypeKeyword, context: context))
    }

    // MARK: - Helper

    private static func collapseModifierLines<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        of decl: Decl,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
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

        Self.diagnose(.modifiersNotOnSameLine, on: modifiers.first!, context: context)

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
