import SwiftSyntax

/// Move leading delimiters to the end of the previous line.
///
/// When a line starts with a comma or colon, the delimiter should instead be placed at the end
/// of the previous line. This keeps the delimiter associated with the preceding expression rather
/// than the following one.
///
/// Lint: A finding is emitted when a delimiter starts a line.
///
/// Format: The delimiter is moved to the end of the previous line.
final class LeadingDotOperators: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    /// Trivia (newline + indentation) saved from a leading delimiter, to be prepended to the
    /// next token's leading trivia.
    private var pendingLeadingTrivia: Trivia?

    /// Trailing comment trivia saved from the token before a leading delimiter. When the previous
    /// line ends with a comment (`5 // first\n    ,`), the comma should be inserted before
    /// the comment: `5, // first\n    bar`.
    private var pendingComment: Trivia?

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        var result = token

        // 1. Apply pending trivia from a previous leading delimiter
        if let pending = pendingLeadingTrivia {
            result = result.with(\.leadingTrivia, pending + result.leadingTrivia)
            pendingLeadingTrivia = nil
        }

        // 2. Check if this token precedes a leading delimiter and has a trailing line comment.
        //    If so, strip the comment so it can be placed after the delimiter.
        if let nextToken = token.nextToken(viewMode: .sourceAccurate),
           isLeadingDelimiter(nextToken),
           result.trailingTrivia.hasLineComment
        {
            pendingComment = result.trailingTrivia
            result = result.with(\.trailingTrivia, Trivia())
        }

        // 3. If this is a leading delimiter, rearrange trivia
        guard isLeadingDelimiter(token) else { return result }

        diagnose(.moveDelimiterToEndOfPreviousLine, on: token)

        // Save the newline + indentation for the next token. Also include any non-space trailing
        // trivia (e.g., block comments that follow the delimiter).
        let trailingNonSpace = result.trailingTrivia.withoutLeadingSpaces()

        pendingLeadingTrivia = trailingNonSpace.isEmpty
            ? token.leadingTrivia : token.leadingTrivia + trailingNonSpace

        // Clear the delimiter's leading trivia (it now sits at the end of the previous line)
        result = result.with(\.leadingTrivia, Trivia())

        // Apply saved trailing comment, or clear trailing trivia
        if let comment = pendingComment {
            result = result.with(\.trailingTrivia, comment)
            pendingComment = nil
        } else {
            result = result.with(\.trailingTrivia, Trivia())
        }

        return result
    }

    /// Returns `true` if the token is a comma or colon with a newline in its leading trivia,
    /// meaning it starts a new line (leading delimiter).
    private func isLeadingDelimiter(_ token: TokenSyntax) -> Bool {
        switch token.tokenKind {
            case .comma, .colon: token.leadingTrivia.containsNewlines
            default: false
        }
    }
}

fileprivate extension Finding.Message {
    static let moveDelimiterToEndOfPreviousLine: Finding.Message =
        "move delimiter to end of previous line"
}
