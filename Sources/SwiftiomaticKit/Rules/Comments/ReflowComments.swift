import SwiftSyntax

/// Reflows contiguous `///` and `//` comment runs to fit `lineLength`.
///
/// DocC structures are preserved: parameter blocks, lists, code fences, block quotes, URLs,
/// inline code spans, and Markdown links are never split mid-token. Continuation lines in
/// `- Parameter:` blocks align under the description column.
///
/// Lint: A comment block whose lines could be redistributed to fit `lineLength` raises a warning.
///
/// Rewrite: The comment block is rebuilt with reflowed prose; code fences and atomic tokens are
/// emitted verbatim.
final class ReflowComments: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .comments }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        let maxWidth = context.configuration[LineLength.self]
        guard maxWidth > 8 else { return token }

        let originalTrivia = token.leadingTrivia
        var pieces = Array(originalTrivia.pieces)
        var i = 0
        var changed = false
        var firstChangedIndex: Int? = nil

        while i < pieces.count {
            // Find a contiguous run of doc-line or line comments separated only by whitespace +
            // newlines. Mixed kinds end the run.
            guard let kind = commentKind(of: pieces[i]) else {
                i += 1
                continue
            }
            let runStart = i
            var runEnd = i
            var lastCommentIndex = i
            var j = i + 1
            scan: while j < pieces.count {
                switch pieces[j] {
                case .spaces, .tabs,
                     .newlines, .carriageReturns, .carriageReturnLineFeeds:
                    j += 1
                default:
                    if commentKind(of: pieces[j]) == kind {
                        lastCommentIndex = j
                        runEnd = j
                        j += 1
                    } else {
                        break scan
                    }
                }
            }
            // Only a single comment in the run? Still try (can be a long single line).
            // Collect bodies and the indent string from the original trivia.
            let indentString = indentationBefore(index: runStart, in: pieces)
            var bodies: [String] = []
            var commentIndices: [Int] = []
            for k in runStart...runEnd {
                if commentKind(of: pieces[k]) != nil {
                    let text = commentText(pieces[k]) ?? ""
                    bodies.append(stripPrefix(text, kind: kind))
                    commentIndices.append(k)
                }
            }
            // Skip directive/special comments — preserve verbatim.
            if bodies.contains(where: { isDirective($0) }) {
                i = lastCommentIndex + 1
                continue
            }
            let prefixLen = kind.prefix.count + 1  // "/// " or "// "
            let availableWidth = max(8, maxWidth - indentString.count - prefixLen)
            guard let reflowed = CommentReflowEngine.reflow(
                lines: bodies,
                availableWidth: availableWidth
            ) else {
                i = lastCommentIndex + 1
                continue
            }
            // Build replacement pieces: comment(line0), [newlines, indent, comment(lineN)] for each
            // remaining line.
            var replacement: [TriviaPiece] = []
            for (idx, body) in reflowed.enumerated() {
                if idx > 0 {
                    replacement.append(.newlines(1))
                    if !indentString.isEmpty {
                        replacement.append(contentsOf: indentTrivia(indentString))
                    }
                }
                let line = body.isEmpty ? kind.prefix : "\(kind.prefix) \(body)"
                replacement.append(makePiece(kind: kind, text: line))
            }
            pieces.replaceSubrange(runStart...runEnd, with: replacement)
            if firstChangedIndex == nil { firstChangedIndex = runStart }
            changed = true
            i = runStart + replacement.count
        }

        guard changed, let anchor = firstChangedIndex else { return token }
        let triviaIdx = originalTrivia.index(originalTrivia.startIndex, offsetBy: min(anchor, originalTrivia.count - 1))
        diagnose(.reflowComment, on: token, anchor: .leadingTrivia(triviaIdx))
        return token.with(\.leadingTrivia, Trivia(pieces: pieces))
    }

    // MARK: - Trivia helpers

    private enum CommentRunKind: Equatable {
        case line, docLine
        var prefix: String {
            switch self {
            case .line: return "//"
            case .docLine: return "///"
            }
        }
    }

    private func commentKind(of piece: TriviaPiece) -> CommentRunKind? {
        switch piece {
        case .lineComment: return .line
        case .docLineComment: return .docLine
        default: return nil
        }
    }

    private func commentText(_ piece: TriviaPiece) -> String? {
        switch piece {
        case .lineComment(let t), .docLineComment(let t): return t
        default: return nil
        }
    }

    private func makePiece(kind: CommentRunKind, text: String) -> TriviaPiece {
        switch kind {
        case .line: return .lineComment(text)
        case .docLine: return .docLineComment(text)
        }
    }

    private func stripPrefix(_ text: String, kind: CommentRunKind) -> String {
        var s = Substring(text)
        if s.hasPrefix(kind.prefix) { s = s.dropFirst(kind.prefix.count) }
        if s.hasPrefix(" ") { s = s.dropFirst() }
        return String(s)
    }

    private func isDirective(_ body: String) -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespaces)
        let directives = [
            "MARK:", "TODO:", "FIXME:", "WARNING:", "NOTE:", "HACK:",
            "sm:ignore", "swift-format-ignore",
            "swiftlint:", "sourcery:",
        ]
        return directives.contains { trimmed.hasPrefix($0) }
    }

    private func indentationBefore(index: Int, in pieces: [TriviaPiece]) -> String {
        var indent = ""
        var j = index - 1
        while j >= 0 {
            switch pieces[j] {
            case .spaces(let n):
                indent = String(repeating: " ", count: n) + indent
                j -= 1
            case .tabs(let n):
                indent = String(repeating: "\t", count: n) + indent
                j -= 1
            case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                return indent
            default:
                return indent
            }
        }
        return indent
    }

    private func indentTrivia(_ indent: String) -> [TriviaPiece] {
        guard !indent.isEmpty else { return [] }
        let spaceCount = indent.filter { $0 == " " }.count
        let tabCount = indent.filter { $0 == "\t" }.count
        var result: [TriviaPiece] = []
        if tabCount > 0 { result.append(.tabs(tabCount)) }
        if spaceCount > 0 { result.append(.spaces(spaceCount)) }
        return result
    }
}

extension Finding.Message {
    fileprivate static let reflowComment: Finding.Message =
        "reflow comment to fit line length"
}
