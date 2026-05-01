import SwiftSyntax

/// Use doc comments for API declarations, otherwise use regular comments.
///
/// Comments immediately before type declarations, properties, methods, and other API-level
/// constructs use `///` doc comment syntax. Comments inside function bodies use `//` regular
/// comment syntax, except for nested function declarations.
///
/// Lint: When a regular comment should be a doc comment, or vice versa.
///
/// Rewrite: The comment style is corrected.
final class ConvertRegularCommentToDocC: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .comments }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Directive prefixes that should never be converted.
    private static let directivePrefixes = [
        "MARK:", "TODO:", "FIXME:", "HACK:", "WARNING:",
        "swiftformat:", "swiftlint:", "sourcery:",
        "sm-ignore",
    ]

    static func transform(
        _ node: MemberBlockItemSyntax,
        parent _: Syntax?,
        context: Context
    ) -> MemberBlockItemSyntax {
        guard isDocCommentableDeclaration(node.decl) else { return node }
        let isConsecutive = isFollowedByConsecutiveMember(node)
        return processTrivia(
            node,
            toDocComment: true,
            preserveRegular: isConsecutive,
            context: context
        )
    }

    static func transform(
        _ node: CodeBlockItemSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemSyntax {
        guard case let .decl(decl) = node.item,
              isDocCommentableDeclaration(decl) else { return node }

        if isAtFileScope(node) {
            let isConsecutive = isFollowedByConsecutiveCodeItem(node)
            return processTrivia(
                node,
                toDocComment: true,
                preserveRegular: isConsecutive,
                context: context
            )
        } else if decl.is(FunctionDeclSyntax.self) {
            return processTrivia(
                node,
                toDocComment: true,
                preserveRegular: false,
                context: context
            )
        } else {
            return processTrivia(
                node,
                toDocComment: false,
                preserveRegular: false,
                context: context
            )
        }
    }

    private static func processTrivia<N: SyntaxProtocol>(
        _ node: N,
        toDocComment: Bool,
        preserveRegular: Bool,
        context: Context
    ) -> N {
        let trivia = node.leadingTrivia
        let hasDirective = containsDirective(trivia)
        let hasBlankLine = hasBlankLineBeforeDeclaration(trivia)

        if toDocComment {
            if hasDirective { return node }

            if hasBlankLine { return convertDocToRegular(node, context: context) }
            return preserveRegular
                ? node
                : convertRegularToDoc(node, context: context)
        } else {
            return convertDocToRegular(node, context: context)
        }
    }

    private static func convertRegularToDoc<N: SyntaxProtocol>(
        _ node: N,
        context: Context
    ) -> N {
        var modified = false
        var newPieces: [TriviaPiece] = []

        for piece in node.leadingTrivia.pieces {
            switch piece {
                case let .lineComment(text):
                    newPieces.append(.docLineComment("/" + text))
                    modified = true
                case let .blockComment(text):
                    newPieces.append(.docBlockComment("/*" + "*" + String(text.dropFirst(2))))
                    modified = true
                default: newPieces.append(piece)
            }
        }

        guard modified else { return node }
        Self.diagnose(.useDocComment, on: node, context: context)
        return node.with(\.leadingTrivia, Trivia(pieces: newPieces))
    }

    private static func convertDocToRegular<N: SyntaxProtocol>(
        _ node: N,
        context: Context
    ) -> N {
        var modified = false
        var newPieces: [TriviaPiece] = []

        for piece in node.leadingTrivia.pieces {
            switch piece {
                case let .docLineComment(text):
                    let slashCount = text.prefix(while: { $0 == "/" }).count
                    guard slashCount <= 3 else {
                        newPieces.append(piece)
                        continue
                    }
                    newPieces.append(.lineComment(String(text.dropFirst())))
                    modified = true
                case let .docBlockComment(text):
                    let starCount = text.dropFirst(2).prefix(while: { $0 == "*" }).count
                    guard starCount <= 1 else {
                        newPieces.append(piece)
                        continue
                    }
                    newPieces.append(.blockComment("/*" + String(text.dropFirst(3))))
                    modified = true
                default: newPieces.append(piece)
            }
        }

        guard modified else { return node }
        Self.diagnose(.useRegularComment, on: node, context: context)
        return node.with(\.leadingTrivia, Trivia(pieces: newPieces))
    }

    private static func isDocCommentableDeclaration(_ decl: DeclSyntax) -> Bool {
        !decl.is(ImportDeclSyntax.self)
            && !decl.is(IfConfigDeclSyntax.self)
            && !decl.is(MissingDeclSyntax.self)
    }

    private static func isAtFileScope(_ node: CodeBlockItemSyntax) -> Bool {
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

    private static func containsDirective(_ trivia: Trivia) -> Bool {
        for piece in trivia.pieces {
            guard case let .lineComment(text) = piece else { continue }
            let body = text.dropFirst(2).drop(while: { $0 == " " })

            if directivePrefixes.contains(where: { body.hasPrefix($0) }) { return true }
        }
        return false
    }

    private static func hasBlankLineBeforeDeclaration(_ trivia: Trivia) -> Bool {
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
                case let .newlines(n): newlines += n
                case let .carriageReturns(n): newlines += n
                case let .carriageReturnLineFeeds(n): newlines += n
                default: break
            }
        }
        return newlines >= 2
    }

    private static func isFollowedByConsecutiveMember(_ node: MemberBlockItemSyntax) -> Bool {
        guard let parent = node.parent?.as(MemberBlockItemListSyntax.self) else { return false }
        var foundSelf = false

        for item in parent {
            if foundSelf { return item.leadingTrivia.totalNewlineCount <= 1 }
            if item.id == node.id { foundSelf = true }
        }
        return false
    }

    private static func isFollowedByConsecutiveCodeItem(_ node: CodeBlockItemSyntax) -> Bool {
        guard let parent = node.parent?.as(CodeBlockItemListSyntax.self) else { return false }
        var foundSelf = false

        for item in parent {
            if foundSelf { return item.leadingTrivia.totalNewlineCount <= 1 }
            if item.id == node.id { foundSelf = true }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let useDocComment: Finding.Message = "use doc comment (///) for API declarations"
    static let useRegularComment: Finding.Message = "use regular comment (//) inside implementation"
}
