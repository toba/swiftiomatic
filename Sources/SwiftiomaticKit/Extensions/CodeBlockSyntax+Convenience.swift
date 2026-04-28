//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension CodeBlockSyntax {
    /// Whether the body is a single statement on a single line with no
    /// internal comments — i.e. it can plausibly stay attached to the
    /// preceding token (e.g. `else { return false }` glued to a wrapped
    /// guard's last condition) rather than dropped onto its own line.
    var isInlineSingleStatementBody: Bool {
        var iter = statements.makeIterator()
        guard let first = iter.next(), iter.next() == nil else { return false }
        // Comments inside the body force it to a multi-line layout — never inline.
        if leftBrace.trailingTrivia.hasAnyComments { return false }
        if first.leadingTrivia.hasAnyComments { return false }
        if first.trailingTrivia.hasAnyComments { return false }
        if rightBrace.leadingTrivia.hasAnyComments { return false }
        // Newlines in the trivia don't disqualify — the formatter may add/remove them
        // each pass; treating the body as an inline candidate based on statement count
        // alone keeps formatting idempotent.
        return true
    }

    /// Like `isInlineSingleStatementBody`, but also requires the user's input to
    /// signal inline intent — `{`, the statement, and `}` all on the same source
    /// line (no newlines in surrounding trivia, no internal newlines in the
    /// statement). Used to opt-in to keeping `else { stmt }` glued when the
    /// surrounding control-flow conditions wrap.
    var hasInlineIntentSingleStatementBody: Bool {
        guard isInlineSingleStatementBody else { return false }
        guard let first = statements.first else { return false }
        if leftBrace.trailingTrivia.containsNewlines { return false }
        if first.leadingTrivia.containsNewlines { return false }
        if first.trailingTrivia.containsNewlines { return false }
        if rightBrace.leadingTrivia.containsNewlines { return false }
        if first.trimmedDescription.contains("\n") { return false }
        return true
    }

    /// Whether this code block's content needs to be wrapped onto new lines.
    /// Returns `true` if the body is non-empty and the first statement or closing
    /// brace is on the same line as the opening brace.
    var bodyNeedsWrapping: Bool {
        guard let firstStmt = statements.first else { return false }
        let firstOnNewLine = firstStmt.leadingTrivia.containsNewlines
        let closingOnNewLine = rightBrace.leadingTrivia.containsNewlines
        return !firstOnNewLine || !closingOnNewLine
    }

    /// Returns a copy with the body content wrapped onto new lines.
    ///
    /// - Parameter baseIndent: The indentation string of the enclosing declaration.
    ///   The body content is indented by `baseIndent + "    "` and the closing brace
    ///   is placed at `baseIndent`.
    func wrappingBody(baseIndent: String) -> CodeBlockSyntax {
        var result = self
        let bodyIndent = baseIndent + "    "

        let firstOnNewLine = statements.first?.leadingTrivia.containsNewlines ?? true
        let closingOnNewLine = rightBrace.leadingTrivia.containsNewlines

        if !firstOnNewLine {
            // Strip trailing spaces from leftBrace (keep comments)
            result.leftBrace = leftBrace.with(
                \.trailingTrivia,
                leftBrace.trailingTrivia.trimmingTrailingWhitespace
            )

            // Set first statement leading trivia to newline + body indent
            var items = Array(result.statements)
            items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
            result.statements = CodeBlockItemListSyntax(items)
        }

        if !closingOnNewLine {
            // Strip trailing whitespace from last statement
            var items = Array(result.statements)
            let lastIdx = items.count - 1
            items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
            result.statements = CodeBlockItemListSyntax(items)

            // Set rightBrace leading trivia to newline + base indent
            result.rightBrace = result.rightBrace.with(
                \.leadingTrivia,
                .newline + Trivia(stringLiteral: baseIndent)
            )
        }

        return result
    }
}
