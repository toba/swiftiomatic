import SwiftSyntax

/// Visitor to find lines that contain only comments.
final class CommentLinesVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter

    private var linesWithComments = Set<Int>()

    /// Lines that contain actual code (not comments).
    private(set) var linesWithCode = Set<Int>()

    /// Lines that contain only comments (and whitespace).
    var commentOnlyLines: Set<Int> {
        linesWithComments.subtracting(linesWithCode)
    }

    /// Initializer.
    ///
    /// - Parameter locationConverter: The location converter to use for mapping positions to line numbers.
    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    /// Compute all comment-only lines in the given file.
    ///
    /// - Parameter file: The source file to analyze.
    /// - Returns: A set of line numbers that contain only comments.
    static func commentLines(in file: SwiftSource) -> Set<Int> {
        CommentLinesVisitor(locationConverter: file.locationConverter)
            .walk(tree: file.syntaxTree, handler: \.commentOnlyLines)
    }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        let leading = TriviaLineCollector.collectLines(
            from: token.leadingTrivia,
            endingAt: token.positionAfterSkippingLeadingTrivia,
            using: locationConverter,
        )
        linesWithComments.formUnion(leading.commentLines)

        // Mark lines with actual code tokens (not comments).
        if token.tokenKind != .endOfFile {
            let tokenLine = locationConverter
                .location(for: token.positionAfterSkippingLeadingTrivia).line
            linesWithCode.insert(tokenLine)
        }

        let trailing = TriviaLineCollector.collectLines(
            from: token.trailingTrivia,
            endingAt: token.endPosition,
            using: locationConverter,
        )
        linesWithComments.formUnion(trailing.commentLines)

        return .visitChildren
    }
}
