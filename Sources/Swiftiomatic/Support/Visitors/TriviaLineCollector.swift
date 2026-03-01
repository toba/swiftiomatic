import SwiftSyntax

/// Shared logic for extracting line ranges from trivia pieces.
/// Used by `CommentLinesVisitor` and `EmptyLinesVisitor`.
enum TriviaLineCollector {
    /// Information about comment and newline line ranges found in a trivia sequence.
    struct Result {
        /// Line numbers spanned by comment trivia pieces.
        var commentLines = Set<Int>()
        /// The highest line number reached by any newline trivia piece, or `nil` if none found.
        var maxNewlineLine: Int?
    }

    /// Scan trivia in reverse (from `endPosition` backward) and collect comment/newline line info.
    ///
    /// - Parameters:
    ///   - trivia: The trivia to scan.
    ///   - endPosition: The absolute position at the end of the trivia.
    ///   - locationConverter: Converter for mapping positions to line numbers.
    /// - Returns: Collected line information.
    static func collectLines(
        from trivia: Trivia,
        endingAt endPosition: AbsolutePosition,
        using locationConverter: SourceLocationConverter,
    ) -> Result {
        var result = Result()
        var currentPosition = endPosition

        for piece in trivia.reversed() {
            currentPosition -= piece.sourceLength

            switch piece {
                case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                    let startLine = locationConverter.location(for: currentPosition).line
                    let endLine = locationConverter
                        .location(for: currentPosition + piece.sourceLength).line
                    result.commentLines.formUnion(startLine ... endLine)
                case .newlines:
                    let endLine = locationConverter
                        .location(for: currentPosition + piece.sourceLength).line
                    result.maxNewlineLine = max(result.maxNewlineLine ?? 0, endLine)
                default:
                    break
            }
        }

        return result
    }
}
