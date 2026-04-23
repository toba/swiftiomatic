import SwiftSyntax

/// Insert blank lines before and after `// MARK:` comments.
///
/// MARK comments serve as section dividers. Surrounding them with blank lines makes the
/// visual separation clear. A blank line before MARK is skipped when the MARK immediately
/// follows an opening brace (start of scope). A blank line after MARK is skipped when
/// the MARK immediately precedes a closing brace (end of scope) or end of file.
///
/// Lint: If a MARK comment is missing a blank line before or after it, a lint warning is raised.
///
/// Format: Blank lines are inserted around MARK comments.
final class BlankLinesAroundMark: RewriteSyntaxRule<BasicRuleValue> {
    override class var key: String { "beforeAndAfterMark" }
    override class var group: ConfigurationGroup? { .blankLines }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        var pieces = Array(token.leadingTrivia.pieces)

        guard
            let markIndex = pieces.firstIndex(where: { piece in
                if case .lineComment(let text) = piece { return text.hasPrefix("// MARK:") }
                return false
            })
        else { return token }

        var changed = false

        // Add blank line BEFORE MARK — skip at start of scope (after `{`).
        let prevToken = token.previousToken(viewMode: .sourceAccurate)
        let isAtStartOfScope = prevToken?.tokenKind == .leftBrace
        if !isAtStartOfScope, let idx = findNewlinesBefore(markIndex, in: pieces) {
            if case .newlines(let n) = pieces[idx], n < 2 {
                diagnose(.insertBlankLineBeforeMark, on: token, anchor: .leadingTrivia(markIndex))
                pieces[idx] = .newlines(n + 1)
                changed = true
            }
        }

        // Add blank line AFTER MARK — skip at end of scope (before `}`) or end of file.
        let isAtEndOfScope = token.tokenKind == .rightBrace
        let isAtEndOfFile = token.tokenKind == .endOfFile
        if !isAtEndOfScope && !isAtEndOfFile {
            if let idx = findNewlinesAfter(markIndex, in: pieces) {
                if case .newlines(let n) = pieces[idx], n < 2 {
                    diagnose(.insertBlankLineAfterMark, on: token)
                    pieces[idx] = .newlines(n + 1)
                    changed = true
                }
            }
        }

        guard changed else { return token }
        return token.with(\.leadingTrivia, Trivia(pieces: pieces))
    }

    /// Find the index of the `.newlines` piece before the MARK comment, skipping spaces/tabs.
    private func findNewlinesBefore(_ markIndex: Int, in pieces: [TriviaPiece]) -> Int? {
        for j in stride(from: markIndex - 1, through: 0, by: -1) {
            if case .newlines = pieces[j] {
                return j
            } else if pieces[j].isSpaceOrTab {
                continue
            } else {
                return nil
            }
        }
        return nil
    }

    /// Find the index of the `.newlines` piece after the MARK comment, skipping spaces/tabs.
    private func findNewlinesAfter(_ markIndex: Int, in pieces: [TriviaPiece]) -> Int? {
        for j in (markIndex + 1)..<pieces.count {
            if case .newlines = pieces[j] {
                return j
            } else if pieces[j].isSpaceOrTab {
                continue
            } else {
                return nil
            }
        }
        return nil
    }
}

extension Finding.Message {
    fileprivate static let insertBlankLineBeforeMark: Finding.Message =
        "insert blank line before MARK comment"

    fileprivate static let insertBlankLineAfterMark: Finding.Message =
        "insert blank line after MARK comment"
}
