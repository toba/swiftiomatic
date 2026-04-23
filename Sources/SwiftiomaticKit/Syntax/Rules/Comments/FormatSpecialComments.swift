import SwiftSyntax

/// Use correct formatting for `TODO:`, `MARK:`, and `FIXME:` comments.
///
/// These special comment tags must be uppercase, followed by a colon and a space. `MARK:` comments
/// with a dash separator must use `// MARK: - text` format. Standalone `/// MARK:` doc comments are
/// converted to `// MARK:` since MARK is not a documentation concept.
///
/// Lint: If a special comment tag is not correctly formatted, a lint warning is raised.
///
/// Format: The comment is reformatted to use the correct style.
final class FormatSpecialComments: RewriteSyntaxRule<BasicRuleValue> {
    override class var key: String { "formatTypePrefix" }
    override class var group: ConfigurationGroup? { .comments }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        var result = token
        var leadingPieces = Array(token.leadingTrivia.pieces)
        var trailingPieces = Array(token.trailingTrivia.pieces)
        var leadingChanged = false
        var trailingChanged = false

        for (index, piece) in leadingPieces.enumerated() {
            if let fixed = fixTriviaPiece(piece, index: index, pieces: leadingPieces) {
                leadingPieces[index] = fixed
                leadingChanged = true
                diagnose(.formatTodoComment, on: token, anchor: .leadingTrivia(index))
            }
        }

        for (index, piece) in trailingPieces.enumerated() {
            if let fixed = fixTriviaPiece(piece, index: index, pieces: trailingPieces) {
                trailingPieces[index] = fixed
                trailingChanged = true
                diagnose(.formatTodoComment, on: token, anchor: .trailingTrivia(index))
            }
        }

        if leadingChanged {
            result = result.with(\.leadingTrivia, Trivia(pieces: leadingPieces))
        }
        if trailingChanged {
            result = result.with(\.trailingTrivia, Trivia(pieces: trailingPieces))
        }
        return result
    }

    /// Fix a single trivia piece if it contains a TODO/MARK/FIXME comment needing formatting.
    private func fixTriviaPiece(
        _ piece: TriviaPiece,
        index: Int,
        pieces: [TriviaPiece]
    ) -> TriviaPiece? {
        switch piece {
        case .lineComment(let text):
            guard let fixed = fixLineComment(text) else { return nil }
            return .lineComment(fixed)

        case .blockComment(let text):
            guard let fixed = fixBlockComment(text) else { return nil }
            return .blockComment(fixed)

        case .docLineComment(let text):
            // Only convert standalone /// with tags to //
            guard !isPartOfDocBlock(index: index, pieces: pieces) else { return nil }
            guard let fixed = fixDocLineComment(text) else { return nil }
            return .lineComment(fixed)

        default:
            return nil
        }
    }

    // MARK: - Line Comments

    /// Fix a `// ...` comment for TODO/MARK/FIXME formatting.
    private func fixLineComment(_ text: String) -> String? {
        guard text.hasPrefix("//") else { return nil }
        let afterSlashes = text.dropFirst(2)
        let spaces = afterSlashes.prefix(while: { $0 == " " })
        let body = afterSlashes.dropFirst(spaces.count)

        guard let fixed = fixCommentBody(String(body)) else { return nil }
        let result = "//" + spaces + fixed
        return result == text ? nil : result
    }

    // MARK: - Block Comments

    /// Fix a `/* ... */` comment for TODO/MARK/FIXME formatting.
    private func fixBlockComment(_ text: String) -> String? {
        guard text.hasPrefix("/*"), text.hasSuffix("*/") else { return nil }
        let inner = text.dropFirst(2).dropLast(2)
        // Only handle single-line block comments
        if inner.contains(where: \.isNewline) { return nil }

        let spaces = inner.prefix(while: { $0 == " " })
        let body = inner.dropFirst(spaces.count)

        // Separate trailing space before */
        let hasTrailingSpace = body.hasSuffix(" ")
        let trimmedBody = hasTrailingSpace ? String(body.dropLast()) : String(body)

        guard let fixed = fixCommentBody(trimmedBody) else { return nil }
        let result = "/*" + spaces + fixed + (hasTrailingSpace ? " " : "") + "*/"
        return result == text ? nil : result
    }

    // MARK: - Doc Line Comments

    /// Fix a standalone `/// ...` comment by converting to `// ...` if it contains a tag.
    private func fixDocLineComment(_ text: String) -> String? {
        guard text.hasPrefix("///") else { return nil }
        let afterSlashes = text.dropFirst(3)
        let spaces = afterSlashes.prefix(while: { $0 == " " })
        let body = afterSlashes.dropFirst(spaces.count)

        // Check if body starts with a recognizable tag
        guard bodyStartsWithTag(String(body)) else { return nil }

        // Convert /// to // and fix body
        let fixedBody = fixCommentBody(String(body)) ?? String(body)
        let effectiveSpaces = spaces.isEmpty ? " " : String(spaces)
        return "//" + effectiveSpaces + fixedBody
    }

    /// Check whether a doc line comment at the given index is part of a multi-line `///` block.
    private func isPartOfDocBlock(index: Int, pieces: [TriviaPiece]) -> Bool {
        // Check before
        for j in stride(from: index - 1, through: 0, by: -1) {
            switch pieces[j] {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                continue
            case .docLineComment:
                return true
            default:
                break
            }
            break
        }
        // Check after
        for j in (index + 1)..<pieces.count {
            switch pieces[j] {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                continue
            case .docLineComment:
                return true
            default:
                break
            }
            break
        }
        return false
    }

    // MARK: - Comment Body Formatting

    /// Check if a comment body starts with a recognized tag (case-insensitive).
    private func bodyStartsWithTag(_ body: String) -> Bool {
        let lowered = body.lowercased()
        return ["todo", "fixme", "mark"].contains { tag in
            guard lowered.hasPrefix(tag) else { return false }
            let after = lowered.dropFirst(tag.count)
            return after.isEmpty || " :-".contains(after.first!)
        }
    }

    /// Fix the body of a comment (after prefix and leading spaces) for tag formatting.
    /// Returns the fixed body, or nil if no change needed.
    private func fixCommentBody(_ body: String) -> String? {
        var normalized = body

        // Apply prefix replacements for tag normalization (case-insensitive)
        let lowered = normalized.lowercased()
        let replacements: [(prefix: String, replacement: String)] = [
            ("todo:", "TODO:"),
            ("todo :", "TODO:"),
            ("fixme:", "FIXME:"),
            ("fixme :", "FIXME:"),
            ("mark:", "MARK:"),
            ("mark :", "MARK:"),
            ("mark-", "MARK: -"),
            ("mark -", "MARK: -"),
        ]

        for replacement in replacements where lowered.hasPrefix(replacement.prefix) {
            normalized = replacement.replacement + normalized.dropFirst(replacement.prefix.count)
            break
        }

        // Find tag at start
        guard let tag = ["TODO", "MARK", "FIXME"].first(where: { normalized.hasPrefix($0) }) else {
            return nil
        }

        var suffix = String(normalized[normalized.index(normalized.startIndex, offsetBy: tag.count)...])

        // If not followed by a space or colon, don't mess with it (may be custom format)
        if let first = suffix.unicodeScalars.first, !" :".unicodeScalars.contains(first) {
            return nil
        }

        // Strip leading spaces and colons
        while let first = suffix.unicodeScalars.first, " :".unicodeScalars.contains(first) {
            suffix = String(suffix.dropFirst())
        }

        // Handle MARK dash spacing
        if tag == "MARK", suffix.hasPrefix("-"), suffix != "-", !suffix.hasPrefix("- ") {
            suffix = "- " + suffix.dropFirst()
        }

        let result = tag + ":" + (suffix.isEmpty ? "" : " \(suffix)")
        return result == body ? nil : result
    }
}

extension Finding.Message {
    fileprivate static let formatTodoComment: Finding.Message =
        "use correct formatting for TODO/MARK/FIXME comment"
}
