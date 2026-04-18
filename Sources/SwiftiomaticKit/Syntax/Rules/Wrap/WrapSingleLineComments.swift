import SwiftSyntax

/// Single-line comments that exceed the configured line length are wrapped.
///
/// Lint: A `//` or `///` comment that exceeds the line length raises a
///       warning.
///
/// Format: The comment is word-wrapped, continuing on the next line with the
///         same prefix and indentation.
final class WrapSingleLineComments: SyntaxFormatRule {
    static let name = "singleLineComments"
    static let group: ConfigGroup? = .wrap
    static let isOptIn = true

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        let maxWidth = context.configuration.lineLength
        guard maxWidth > 3 else { return token }

        let originalTrivia = token.leadingTrivia
        var pieces = Array(originalTrivia.pieces)
        var changed = false
        // Track the first comment trivia index (in the original trivia) for diagnose anchor
        var firstCommentOriginalIndex: Int?
        // Map from current `pieces` index to original trivia index
        var originalIndexMap = Array(0..<pieces.count)
        var i = 0

        while i < pieces.count {
            switch pieces[i] {
            case .lineComment(let text):
                let result = tryWrap(
                    text: text,
                    prefix: "//",
                    triviaKind: .lineComment,
                    index: i,
                    pieces: &pieces,
                    originalIndexMap: &originalIndexMap,
                    maxWidth: maxWidth
                )
                if result.didChange {
                    changed = true
                    if firstCommentOriginalIndex == nil {
                        firstCommentOriginalIndex = result.originalIndex
                    }
                    i += result.advance
                } else {
                    i += 1
                }

            case .docLineComment(let text):
                let result = tryWrap(
                    text: text,
                    prefix: "///",
                    triviaKind: .docLineComment,
                    index: i,
                    pieces: &pieces,
                    originalIndexMap: &originalIndexMap,
                    maxWidth: maxWidth
                )
                if result.didChange {
                    changed = true
                    if firstCommentOriginalIndex == nil {
                        firstCommentOriginalIndex = result.originalIndex
                    }
                    i += result.advance
                } else {
                    i += 1
                }

            default:
                i += 1
            }
        }

        guard changed, let anchorOrigIdx = firstCommentOriginalIndex else { return token }

        // Use the original trivia index for anchor
        let triviaIdx = originalTrivia.index(
            originalTrivia.startIndex,
            offsetBy: anchorOrigIdx
        )
        diagnose(.wrapComment, on: token, anchor: .leadingTrivia(triviaIdx))

        return token.with(\.leadingTrivia, Trivia(pieces: pieces))
    }

    // MARK: - Wrapping logic

    private enum CommentKind {
        case lineComment
        case docLineComment
    }

    private struct WrapResult {
        var didChange: Bool
        var advance: Int
        var originalIndex: Int
    }

    private func tryWrap(
        text: String,
        prefix: String,
        triviaKind: CommentKind,
        index: Int,
        pieces: inout [TriviaPiece],
        originalIndexMap: inout [Int],
        maxWidth: Int
    ) -> WrapResult {
        let indent = indentationBefore(index: index, in: pieces)
        let column = indent.count
        guard column + text.count > maxWidth else {
            return WrapResult(didChange: false, advance: 1, originalIndex: 0)
        }
        guard !isCommentDirective(text) else {
            return WrapResult(didChange: false, advance: 1, originalIndex: 0)
        }
        let wrapped = wrapComment(
            text: text,
            prefix: prefix,
            column: column,
            maxWidth: maxWidth
        )
        guard wrapped.count > 1 else {
            return WrapResult(didChange: false, advance: 1, originalIndex: 0)
        }

        let origIdx = originalIndexMap[index]

        // Build replacement trivia pieces
        var replacement = [TriviaPiece]()
        for (j, line) in wrapped.enumerated() {
            if j > 0 {
                replacement.append(.newlines(1))
                if !indent.isEmpty {
                    replacement.append(contentsOf: indentPieces(indent))
                }
            }
            let piece: TriviaPiece =
                switch triviaKind {
                case .lineComment: .lineComment(line)
                case .docLineComment: .docLineComment(line)
                }
            replacement.append(piece)
        }

        // Update the original index map
        let newIndices = Array(repeating: origIdx, count: replacement.count)
        originalIndexMap.replaceSubrange(index...index, with: newIndices)

        pieces.replaceSubrange(index...index, with: replacement)

        return WrapResult(didChange: true, advance: replacement.count, originalIndex: origIdx)
    }

    // MARK: - Helpers

    /// Returns the indentation string before the comment at the given index.
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

    /// Converts an indentation string back to trivia pieces.
    private func indentPieces(_ indent: String) -> [TriviaPiece] {
        guard !indent.isEmpty else { return [] }
        let spaceCount = indent.filter { $0 == " " }.count
        let tabCount = indent.filter { $0 == "\t" }.count
        var result = [TriviaPiece]()
        if tabCount > 0 { result.append(.tabs(tabCount)) }
        if spaceCount > 0 { result.append(.spaces(spaceCount)) }
        return result
    }

    /// Word-wraps a comment to fit within maxWidth, returning multiple lines.
    private func wrapComment(
        text: String,
        prefix: String,
        column: Int,
        maxWidth: Int
    ) -> [String] {
        var body = text.dropFirst(prefix.count)
        let hasSpace = body.hasPrefix(" ")
        if hasSpace { body = body.dropFirst() }
        let continuationPrefix = hasSpace ? "\(prefix) " : prefix

        var words = body.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        guard !words.isEmpty else { return [text] }

        var lines = [String]()
        var currentLine = prefix + (hasSpace ? " " : "") + words.removeFirst()
        var currentLength = column + currentLine.count

        for word in words {
            let wordLength = word.count + 1
            if currentLength + wordLength <= maxWidth
                || column + continuationPrefix.count + word.count > maxWidth
            {
                currentLine += " " + word
                currentLength += wordLength
            } else {
                lines.append(currentLine)
                currentLine = continuationPrefix + word
                currentLength = column + currentLine.count
            }
        }
        lines.append(currentLine)

        guard lines.count > 1 else { return [text] }
        guard lines.last != continuationPrefix else { return [text] }

        return lines
    }

    /// Returns `true` if the comment is a directive that should not be wrapped.
    private func isCommentDirective(_ text: String) -> Bool {
        let body = text.drop { $0 == "/" }.trimmingCharacters(in: .whitespaces)
        let directives = [
            "MARK:", "TODO:", "FIXME:", "WARNING:", "NOTE:", "HACK:",
            "swiftiomatic-ignore", "swift-format-ignore",
            "swiftlint:", "sourcery:",
        ]
        return directives.contains { body.hasPrefix($0) }
    }
}

extension Finding.Message {
    fileprivate static let wrapComment: Finding.Message =
        "wrap comment to fit within line length"
}
