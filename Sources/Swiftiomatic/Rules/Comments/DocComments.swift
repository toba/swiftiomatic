import SwiftSyntax

/// Use doc comments for API declarations, otherwise use regular comments.
///
/// Comments immediately before type declarations, properties, methods, and other
/// API-level constructs use `///` doc comment syntax. Comments inside function
/// bodies use `//` regular comment syntax, except for nested function declarations.
///
/// Lint: When a regular comment should be a doc comment, or vice versa.
///
/// Format: The comment style is corrected.
final class DocComments: SyntaxFormatRule {
    static let name = "convertRegularCommentToDocC"
    static let isOptIn = true
    static let group: ConfigGroup? = .comments

    /// Directive prefixes that should never be converted.
    private static let directivePrefixes = [
        "MARK:", "TODO:", "FIXME:", "HACK:", "WARNING:",
        "swiftformat:", "swiftlint:", "sourcery:",
        "sm-ignore",
    ]

    // MARK: - Member Block Items (Type Bodies — API Scope)

    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        let visited = super.visit(node)
        guard isDocCommentableDeclaration(visited.decl) else { return visited }
        let isConsecutive = isFollowedByConsecutiveMember(node)
        return processTrivia(
            visited,
            toDocComment: true,
            preserveRegular: isConsecutive,
            original: node
        )
    }

    // MARK: - Code Block Items (File Scope or Local Scope)

    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        let visited = super.visit(node)
        guard case .decl(let decl) = visited.item,
            isDocCommentableDeclaration(decl)
        else { return visited }

        if isAtFileScope(node) {
            let isConsecutive = isFollowedByConsecutiveCodeItem(node)
            return processTrivia(
                visited,
                toDocComment: true,
                preserveRegular: isConsecutive,
                original: node
            )
        } else if decl.is(FunctionDeclSyntax.self) {
            // Nested functions still get doc comments
            return processTrivia(
                visited,
                toDocComment: true,
                preserveRegular: false,
                original: node
            )
        } else {
            // Local scope: convert /// to //
            return processTrivia(
                visited,
                toDocComment: false,
                preserveRegular: false,
                original: node
            )
        }
    }

    // MARK: - Trivia Processing

    private func processTrivia<N: SyntaxProtocol>(
        _ node: N,
        toDocComment: Bool,
        preserveRegular: Bool,
        original: some SyntaxProtocol
    ) -> N {
        let trivia = node.leadingTrivia
        let hasDirective = containsDirective(trivia)
        let hasBlankLine = hasBlankLineBeforeDeclaration(trivia)

        if toDocComment {
            if hasDirective { return node }
            if hasBlankLine {
                // Doc comments separated by blank line → convert to regular
                return convertDocToRegular(node, original: original)
            }
            if preserveRegular { return node }
            return convertRegularToDoc(node, original: original)
        } else {
            return convertDocToRegular(node, original: original)
        }
    }

    private func convertRegularToDoc<N: SyntaxProtocol>(
        _ node: N,
        original: some SyntaxProtocol
    ) -> N {
        var modified = false
        var newPieces: [TriviaPiece] = []

        for piece in node.leadingTrivia.pieces {
            switch piece {
            case .lineComment(let text):
                newPieces.append(.docLineComment("/" + text))
                modified = true
            case .blockComment(let text):
                newPieces.append(.docBlockComment("/*" + "*" + String(text.dropFirst(2))))
                modified = true
            default:
                newPieces.append(piece)
            }
        }

        guard modified else { return node }
        diagnose(.useDocComment, on: original)
        return node.with(\.leadingTrivia, Trivia(pieces: newPieces))
    }

    private func convertDocToRegular<N: SyntaxProtocol>(
        _ node: N,
        original: some SyntaxProtocol
    ) -> N {
        var modified = false
        var newPieces: [TriviaPiece] = []

        for piece in node.leadingTrivia.pieces {
            switch piece {
            case .docLineComment(let text):
                let slashCount = text.prefix(while: { $0 == "/" }).count
                guard slashCount <= 3 else {
                    newPieces.append(piece)
                    continue
                }
                newPieces.append(.lineComment(String(text.dropFirst())))
                modified = true
            case .docBlockComment(let text):
                let starCount = text.dropFirst(2).prefix(while: { $0 == "*" }).count
                guard starCount <= 1 else {
                    newPieces.append(piece)
                    continue
                }
                newPieces.append(.blockComment("/*" + String(text.dropFirst(3))))
                modified = true
            default:
                newPieces.append(piece)
            }
        }

        guard modified else { return node }
        diagnose(.useRegularComment, on: original)
        return node.with(\.leadingTrivia, Trivia(pieces: newPieces))
    }

    // MARK: - Helpers

    private func isDocCommentableDeclaration(_ decl: DeclSyntax) -> Bool {
        !decl.is(ImportDeclSyntax.self)
            && !decl.is(IfConfigDeclSyntax.self)
            && !decl.is(MissingDeclSyntax.self)
    }

    private func isAtFileScope(_ node: CodeBlockItemSyntax) -> Bool {
        var current: Syntax? = Syntax(node).parent
        while let parent = current {
            if parent.is(SourceFileSyntax.self) { return true }
            if parent.is(CodeBlockSyntax.self) { return false }
            if parent.is(ClosureExprSyntax.self) { return false }
            if parent.is(MemberBlockSyntax.self) { return false }
            if parent.is(SwitchCaseSyntax.self) { return false }
            current = parent.parent
        }
        return false
    }

    private func containsDirective(_ trivia: Trivia) -> Bool {
        for piece in trivia.pieces {
            guard case .lineComment(let text) = piece else { continue }
            let body = text.dropFirst(2).drop(while: { $0 == " " })
            if Self.directivePrefixes.contains(where: { body.hasPrefix($0) }) {
                return true
            }
        }
        return false
    }

    private func hasBlankLineBeforeDeclaration(_ trivia: Trivia) -> Bool {
        // Find the last comment piece, then check for 2+ newlines after it
        var lastCommentIndex: Int?
        for (i, piece) in trivia.pieces.enumerated() {
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                lastCommentIndex = i
            default: break
            }
        }
        guard let idx = lastCommentIndex else { return false }

        var newlines = 0
        for piece in trivia.pieces[(idx + 1)...] {
            switch piece {
            case .newlines(let n): newlines += n
            case .carriageReturns(let n): newlines += n
            case .carriageReturnLineFeeds(let n): newlines += n
            default: break
            }
        }
        return newlines >= 2
    }

    /// Whether the next sibling member block item starts on the immediately
    /// following line (no blank line between them), indicating consecutive
    /// declarations where the comment is likely a section header.
    private func isFollowedByConsecutiveMember(_ node: MemberBlockItemSyntax) -> Bool {
        guard let parent = node.parent?.as(MemberBlockItemListSyntax.self) else { return false }
        var foundSelf = false
        for item in parent {
            if foundSelf {
                return item.leadingTrivia.totalNewlineCount <= 1
            }
            if item.id == node.id { foundSelf = true }
        }
        return false
    }

    private func isFollowedByConsecutiveCodeItem(_ node: CodeBlockItemSyntax) -> Bool {
        guard let parent = node.parent?.as(CodeBlockItemListSyntax.self) else { return false }
        var foundSelf = false
        for item in parent {
            if foundSelf {
                return item.leadingTrivia.totalNewlineCount <= 1
            }
            if item.id == node.id { foundSelf = true }
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let useDocComment: Finding.Message =
        "use doc comment (///) for API declarations"
    fileprivate static let useRegularComment: Finding.Message =
        "use regular comment (//) inside implementation"
}
