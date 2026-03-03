import SwiftSyntax

/// Extracts line-range information from trivia pieces
///
/// Shared by ``CommentLinesVisitor`` and ``EmptyLinesVisitor`` to avoid
/// duplicating trivia scanning logic.
enum TriviaLineCollector {
    /// Comment and newline line-range data extracted from a trivia sequence
    struct Result {
        /// Line numbers spanned by comment trivia pieces
        var commentLines = Set<Int>()
        /// The highest line number reached by any newline trivia piece, or `nil` if none were found
        var maxNewlineLine: Int?
    }

    /// Scans trivia in reverse from `endPosition` and collects comment and newline line info
    ///
    /// - Parameters:
    ///   - trivia: The trivia to scan.
    ///   - endPosition: The absolute position at the end of the trivia.
    ///   - locationConverter: Converter for mapping positions to line numbers.
    /// - Returns: A ``Result`` with the collected line information.
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
                    let endLine =
                        locationConverter
                            .location(for: currentPosition + piece.sourceLength).line
                    result.commentLines.formUnion(startLine ... endLine)
                case .newlines:
                    let endLine =
                        locationConverter
                            .location(for: currentPosition + piece.sourceLength).line
                    result.maxNewlineLine = max(result.maxNewlineLine ?? 0, endLine)
                default:
                    break
            }
        }

        return result
    }
}
