import SwiftSyntax

/// Ensure the file ends with exactly one newline.
///
/// Many Unix tools expect files to end with a newline. Missing trailing newlines cause
/// `diff` noise and `cat` concatenation issues. Extra trailing newlines waste space.
///
/// Lint: If the file does not end with exactly one newline, a lint warning is raised.
///
/// Format: A trailing newline is added if missing, or extra newlines are removed.
final class LinebreakAtEndOfFile: SyntaxFormatRule {
    static let name = "ensureLineBreakAtEOF"
    static let group: ConfigGroup? = .lineBreaks
    static let isOptIn = true

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let eof = node.endOfFileToken
        let newlineCount = eof.leadingTrivia.pieces.reduce(0) { count, piece in
            if case .newlines(let n) = piece { return count + n }
            return count
        }

        if newlineCount == 1 { return node }

        if newlineCount == 0 {
            diagnose(.addTrailingNewline, on: eof)
            var result = node
            result.endOfFileToken = eof.with(\.leadingTrivia, .newline)
            return result
        }

        // Multiple trailing newlines — reduce to exactly one.
        diagnose(.removeExtraTrailingNewlines, on: eof)
        var result = node
        result.endOfFileToken = eof.with(\.leadingTrivia, .newline)
        return result
    }
}

extension Finding.Message {
    fileprivate static let addTrailingNewline: Finding.Message =
        "add trailing newline at end of file"

    fileprivate static let removeExtraTrailingNewlines: Finding.Message =
        "remove extra trailing newlines at end of file"
}
