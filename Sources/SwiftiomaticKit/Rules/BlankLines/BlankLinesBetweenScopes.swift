import SwiftSyntax

/// Insert a blank line after declarations with multi-line bodies.
///
/// When a type declaration (class, struct, enum, extension, protocol, actor) or function
/// declaration has a multi-line body, a blank line after it improves readability by
/// visually separating it from the next declaration. Single-line (inline) bodies are
/// excluded. This rule operates at the top level and inside type member blocks — not
/// inside function bodies (if/for/while don't need separation).
///
/// Lint: If a multi-line scoped declaration is not followed by a blank line, a lint
///       warning is raised.
///
/// Rewrite: A blank line is inserted after the declaration.
final class BlankLinesBetweenScopes: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "betweenScopes" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        var result = super.visit(node)
        result.statements = ensureBlankLines(in: result.statements)
        return result
    }

    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
        let visited = super.visit(node)
        var result = visited
        result.members = ensureBlankLines(
            inMembers: visited.members,
            diagnosing: node.members
        )
        return result
    }

    // MARK: - CodeBlockItemListSyntax (top-level)

    private func ensureBlankLines(in statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax
    {
        let original = Array(statements)
        var items = original
        var modified = false
        let braceIsBlank = context.configuration[ClosingBraceAsBlankLine.self]
        let commentIsBlank = context.configuration[CommentAsBlankLine.self]

        for i in 0..<(original.count - 1) {
            guard case .decl(let decl) = original[i].item,
                hasDeclMultiLineBody(decl)
            else { continue }
            let nextIndex = i + 1
            guard !original[nextIndex].leadingTrivia.hasBlankLine else { continue }
            if braceIsBlank { continue }
            if commentIsBlank, original[nextIndex].leadingTrivia.startsWithComment { continue }

            diagnose(.insertBlankLineAfterScope, on: original[nextIndex].item)
            var next = original[nextIndex]
            next.leadingTrivia = .newline + next.leadingTrivia
            items[nextIndex] = next
            modified = true
        }

        guard modified else { return statements }
        return CodeBlockItemListSyntax(items)
    }

    // MARK: - MemberBlockItemListSyntax (type members)

    private func ensureBlankLines(
        inMembers members: MemberBlockItemListSyntax,
        diagnosing originalMembers: MemberBlockItemListSyntax
    ) -> MemberBlockItemListSyntax {
        let original = Array(members)
        let diagTargets = Array(originalMembers)
        var items = original
        var modified = false

        let braceIsBlank = context.configuration[ClosingBraceAsBlankLine.self]
        let commentIsBlank = context.configuration[CommentAsBlankLine.self]

        for i in 0..<(original.count - 1) {
            guard hasDeclMultiLineBody(original[i].decl) else { continue }
            let nextIndex = i + 1
            guard !original[nextIndex].leadingTrivia.hasBlankLine else { continue }
            if braceIsBlank { continue }
            if commentIsBlank, original[nextIndex].leadingTrivia.startsWithComment { continue }

            diagnose(.insertBlankLineAfterScope, on: diagTargets[nextIndex].decl)
            var next = original[nextIndex]
            next.leadingTrivia = .newline + next.leadingTrivia
            items[nextIndex] = next
            modified = true
        }

        guard modified else { return members }
        return MemberBlockItemListSyntax(items)
    }

    // MARK: - Helpers

    /// A declaration has a multi-line body if its last token is `}` with newlines in its
    /// leading trivia (meaning the closing brace is on a separate line from the content).
    private func hasDeclMultiLineBody(_ decl: DeclSyntax) -> Bool {
        guard let lastToken = decl.lastToken(viewMode: .sourceAccurate),
            lastToken.tokenKind == .rightBrace
        else { return false }
        return lastToken.leadingTrivia.containsNewlines
    }

}

extension Finding.Message {
    fileprivate static let insertBlankLineAfterScope: Finding.Message =
        "insert blank line after scoped declaration"
}
