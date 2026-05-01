import SwiftSyntax

/// Place doc comments before any declaration modifiers or attributes.
///
/// Doc comments ( `///` or `/** */` ) should appear before all attributes and access modifiers, not
/// between them.
///
/// Lint: If a doc comment appears after an attribute or modifier, a lint warning is raised.
///
/// Rewrite: The doc comment is moved before all attributes and modifiers.
final class PlaceDocCommentsBeforeModifiers: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .comments }

    // MARK: - Container types (need super.visit)

    static func transform(
        _ node: StructDeclSyntax,
        original _: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.structKeyword, context: context))
    }

    static func transform(
        _ node: ClassDeclSyntax,
        original _: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.classKeyword, context: context))
    }

    static func transform(
        _ node: EnumDeclSyntax,
        original _: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.enumKeyword, context: context))
    }

    static func transform(
        _ node: ActorDeclSyntax,
        original _: ActorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.actorKeyword, context: context))
    }

    static func transform(
        _ node: ProtocolDeclSyntax,
        original _: ProtocolDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.protocolKeyword, context: context))
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        original _: ExtensionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(
            moveDocComments(
                in: node,
                keywordKeyPath: \.extensionKeyword,
                context: context
            ))
    }

    // MARK: - Leaf declarations

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.funcKeyword, context: context))
    }

    static func transform(
        _ node: VariableDeclSyntax,
        original _: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(
            moveDocComments(
                in: node,
                keywordKeyPath: \.bindingSpecifier,
                context: context
            ))
    }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        original _: TypeAliasDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(
            moveDocComments(
                in: node,
                keywordKeyPath: \.typealiasKeyword,
                context: context
            ))
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        original _: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(moveDocComments(in: node, keywordKeyPath: \.initKeyword, context: context))
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        original _: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(
            moveDocComments(
                in: node,
                keywordKeyPath: \.subscriptKeyword,
                context: context
            ))
    }

    // MARK: - Core logic

    private static func moveDocComments<D: SyntaxProtocol>(
        in decl: D,
        keywordKeyPath: WritableKeyPath<D, TokenSyntax>,
        context: Context
    ) -> D where D: WithAttributesSyntax, D: WithModifiersSyntax {
        let hasAttributes = !decl.attributes.isEmpty
        let hasModifiers = !decl.modifiers.isEmpty
        guard hasAttributes || hasModifiers else { return decl }

        var result = decl
        var collectedDoc = [TriviaPiece]()

        // Check keyword's leading trivia for doc comments
        if let extracted = extractDocBlock(from: result[keyPath: keywordKeyPath].leadingTrivia) {
            result[keyPath: keywordKeyPath].leadingTrivia = extracted.cleaned
            collectedDoc.insert(contentsOf: extracted.docBlock, at: 0)
        }

        // Check modifiers' leading trivia (skip first modifier if it IS the first position)
        var modifiers = result.modifiers

        for i in modifiers.indices.reversed() {
            let isFirstPosition = i == modifiers.startIndex && !hasAttributes
            if isFirstPosition { continue }

            if let extracted = extractDocBlock(from: modifiers[i].leadingTrivia) {
                modifiers[i].leadingTrivia = extracted.cleaned
                collectedDoc.insert(contentsOf: extracted.docBlock, at: 0)
            }
        }
        result.modifiers = modifiers

        guard !collectedDoc.isEmpty else { return decl }
        Self.diagnose(
            .docCommentsBeforeModifiers, on: decl[keyPath: keywordKeyPath], context: context)

        // Insert doc block into the first position's leading trivia
        if hasAttributes {
            var attrs = result.attributes
            let idx = attrs.startIndex
            attrs[idx].leadingTrivia = insertDocBlock(
                collectedDoc,
                into: attrs[idx].leadingTrivia
            )
            result.attributes = attrs
        } else {
            var mods = result.modifiers
            let idx = mods.startIndex
            mods[idx].leadingTrivia = insertDocBlock(
                collectedDoc,
                into: mods[idx].leadingTrivia
            )
            result.modifiers = mods
        }

        return result
    }

    // MARK: - Trivia helpers

    /// Extract doc comment pieces from trivia. Returns nil if no doc comments found.
    private static func extractDocBlock(
        from trivia: Trivia
    ) -> (cleaned: Trivia, docBlock: [TriviaPiece])? {
        let pieces = Array(trivia.pieces)
        guard pieces.contains(where: \.isDocComment) else { return nil }

        var cleaned = [TriviaPiece]()
        var docBlock = [TriviaPiece]()
        var whitespaceBuffer = [TriviaPiece]()
        var foundDoc = false

        for piece in pieces {
            if piece.isDocComment {
                if !foundDoc {
                    foundDoc = true
                    // First doc: keep newlines in cleaned, take trailing spaces/tabs as indent for
                    // doc
                    var splitIdx = whitespaceBuffer.count

                    while splitIdx > 0, whitespaceBuffer[splitIdx - 1].isSpaceOrTab {
                        splitIdx -= 1
                    }
                    cleaned.append(contentsOf: whitespaceBuffer[..<splitIdx])
                    docBlock.append(contentsOf: whitespaceBuffer[splitIdx...])
                } else {
                    // Continuation: all whitespace (newline + indent) belongs to doc block
                    docBlock.append(contentsOf: whitespaceBuffer)
                }
                whitespaceBuffer = []
                docBlock.append(piece)
            } else if piece.isWhitespace {
                whitespaceBuffer.append(piece)
            } else {
                // Non-doc content (regular comment, etc.)
                if foundDoc {
                    cleaned.append(contentsOf: whitespaceBuffer)
                    whitespaceBuffer = []
                    foundDoc = false
                } else {
                    cleaned.append(contentsOf: whitespaceBuffer)
                    whitespaceBuffer = []
                }
                cleaned.append(piece)
            }
        }

        // Handle trailing whitespace after doc block
        if foundDoc {
            // Include first newline in doc block; leave rest (indent) for the token
            var tookNewline = false

            for piece in whitespaceBuffer {
                if !tookNewline, piece.isNewline {
                    docBlock.append(piece)
                    tookNewline = true
                } else {
                    cleaned.append(piece)
                }
            }
        } else {
            cleaned.append(contentsOf: whitespaceBuffer)
        }

        return (Trivia(pieces: cleaned), docBlock)
    }

    /// Insert doc block pieces into target trivia, placing doc before the trailing indent.
    private static func insertDocBlock(_ docBlock: [TriviaPiece], into trivia: Trivia) -> Trivia {
        let pieces = Array(trivia.pieces)

        // Split target into structural (newlines etc) and trailing indent (spaces/tabs)
        var indentStart = pieces.count
        while indentStart > 0, pieces[indentStart - 1].isSpaceOrTab { indentStart -= 1 }

        let structural = Array(pieces[..<indentStart])
        let indent = Array(pieces[indentStart...])

        return .init(pieces: structural + docBlock + indent)
    }
}

fileprivate extension Finding.Message {
    static let docCommentsBeforeModifiers: Finding.Message =
        "place doc comments before attributes and modifiers"
}
