import SwiftSyntax

/// Preserve discretionary line breaks.
package struct RespectsExistingLineBreaks: LayoutRule {
    package static let key = "respectExisting"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Preserve discretionary line breaks."
    package static let defaultValue = true
}

extension TokenStream {
    /// Returns a value indicating whether or not discretionary newlines are permitted before the
    /// given syntax token.
    ///
    /// Discretionary newlines are allowed before any token (ignoring open/close group tokens, which
    /// do not contribute to this) that is preceded by an existing newline or that is preceded by a
    /// break whose `ignoresDiscretionary` property is false. In other words, this means that users
    /// may insert their own breaks in places where the pretty printer allows them, even if those
    /// breaks wouldn't cause wrapping based on the column limit, but they may not place them in
    /// places where the pretty printer would not break (for example, at a space token that is
    /// intended to keep two tokens glued together).
    ///
    /// Furthermore, breaks with `ignoresDiscretionary` equal to `true` are in effect "last resort"
    /// breaks; a user's newline will be discarded unless the algorithm *must* break there. For
    /// example, an open curly brace on a non-continuation line should always be kept on the same line
    /// as the tokens before it unless the tokens before it are exactly the length of the line and a
    /// break must be inserted there to prevent the brace from going over the limit.
    func isDiscretionaryNewlineAllowed(before token: TokenSyntax) -> Bool {
        func isBreakMoreRecentThanNonbreakingContent(_ tokens: [Token]) -> Bool? {
            for token in tokens.reversed() as ReversedCollection {
                switch token {
                case .break(_, _, .elective(ignoresDiscretionary: true, _)): return false
                case .break: return true
                case .comment, .space, .syntax, .verbatim: return false
                default: break
                }
            }
            return nil
        }

        // First, check the pretty printer tokens that will be added before the text token. If we find
        // a break or newline before we find some other text, we allow a discretionary newline. If we
        // find some other content, we don't allow it.
        //
        // If there were no before tokens, then we do the same check the token stream created thus far,
        // returning true if there were no tokens at all in the stream (which would mean there was a
        // discretionary newline at the beginning of the file).
        if let beforeTokens = beforeMap[token],
            let foundBreakFirst = isBreakMoreRecentThanNonbreakingContent(beforeTokens)
        {
            return foundBreakFirst
        }
        return isBreakMoreRecentThanNonbreakingContent(tokens) ?? true
    }

    /// Returns a value indicating whether a statement or member declaration should have a newline
    /// inserted after it, based on the presence of a semicolon and whether or not the formatter is
    /// respecting existing newlines.
    func shouldInsertNewline(basedOn semicolon: TokenSyntax?) -> Bool {
        if config[RespectsExistingLineBreaks.self] {
            // If we are respecting existing newlines, then we only want to force a newline at the end of
            // statements and declarations that don't have a semicolon (i.e., where they are required).
            return semicolon == nil
        } else {
            // If we are not respecting existing newlines, then we always force a newline (this forces
            // even semicolon-delimited statements onto separate lines).
            return true
        }
    }
}
