import SwiftSyntax

/// Move leading delimiters to the end of the previous line.
///
/// When a line starts with a comma or colon, the delimiter should instead be placed at the end of
/// the previous line. This keeps the delimiter associated with the preceding expression rather than
/// the following one.
///
/// Lint: A finding is emitted when a delimiter starts a line.
///
/// Rewrite: The delimiter is moved to the end of the previous line.
final class LeadingDotOperators: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        /// Trivia (newline + indentation) saved from a leading delimiter, to be prepended to the
        /// next token's leading trivia.
        var pendingLeadingTrivia: Trivia?

        /// Trailing comment trivia saved from the token before a leading delimiter.
        var pendingComment: Trivia?
    }

    static func transform(
        _ token: TokenSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TokenSyntax {
        let state = context.leadingDotOperatorsState
        var result = token

        // 1. Apply pending trivia from a previous leading delimiter
        if let pending = state.pendingLeadingTrivia {
            result = result.with(\.leadingTrivia, pending + result.leadingTrivia)
            state.pendingLeadingTrivia = nil
        }

        // 2. Check if this token precedes a leading delimiter and has a trailing line comment. If
        //    so, strip the comment so it can be placed after the delimiter.
        if let nextToken = token.nextToken(viewMode: .sourceAccurate),
           isLeadingDelimiter(nextToken),
           result.trailingTrivia.hasLineComment
        {
            state.pendingComment = result.trailingTrivia
            result = result.with(\.trailingTrivia, Trivia())
        }

        // 3. If this is a leading delimiter, rearrange trivia
        guard isLeadingDelimiter(token) else { return result }

        Self.diagnose(.moveDelimiterToEndOfPreviousLine, on: token, context: context)

        // Save the newline + indentation for the next token. Also include any non-space trailing
        // trivia (e.g., block comments that follow the delimiter).
        let trailingNonSpace = result.trailingTrivia.withoutLeadingSpaces()

        state.pendingLeadingTrivia = trailingNonSpace.isEmpty
            ? token.leadingTrivia
            : token.leadingTrivia + trailingNonSpace

        // Clear the delimiter's leading trivia (it now sits at the end of the previous line)
        result = result.with(\.leadingTrivia, Trivia())

        // Apply saved trailing comment, or clear trailing trivia
        if let comment = state.pendingComment {
            result = result.with(\.trailingTrivia, comment)
            state.pendingComment = nil
        } else {
            result = result.with(\.trailingTrivia, Trivia())
        }

        return result
    }

    /// Returns `true` if the token is a comma or colon with a newline in its leading trivia,
    /// meaning it starts a new line (leading delimiter).
    private static func isLeadingDelimiter(_ token: TokenSyntax) -> Bool {
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
