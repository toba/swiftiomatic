import SwiftSyntax

/// Multiline string literal reflow mode.
package struct ReflowMultilineStringLiterals: LayoutRule {
    package static let key = "reflowMultilineStringLiterals"
    package static let description = "Multiline string literal reflow mode."
    package static let defaultValue: MultilineStringReflowBehavior = .never
}

package enum MultilineStringReflowBehavior: String, Codable, Sendable {
    case never
    case onlyLinesOverLength
    case always

    var isNever: Bool { self == .never }
    var isAlways: Bool { self == .always }
}

extension TokenStream {
    // Insert an `.escaped` break token after each series of whitespace in a substring
    func emitMultilineSegmentTextTokens(breakKind: BreakKind, segment: Substring) {
        var currentWord = [Unicode.Scalar]()
        var currentBreak = [Unicode.Scalar]()

        func emitWord() {
            if !currentWord.isEmpty {
                var str = ""
                str.unicodeScalars.append(contentsOf: currentWord)
                appendToken(.syntax(str))
                currentWord = []
            }
        }
        func emitBreak() {
            if !currentBreak.isEmpty {
                // We append this as a syntax, instead of a `.space`, so that it is always included in the output.
                var str = ""
                str.unicodeScalars.append(contentsOf: currentBreak)
                appendToken(.syntax(str))
                appendToken(.break(breakKind, size: 0, newlines: .escaped))
                currentBreak = []
            }
        }

        for scalar in segment.unicodeScalars {
            // We don't have to worry about newlines occurring in segments.
            // Either a segment will end in a newline character or the newline will be in trivia.
            if scalar.properties.isWhitespace {
                emitWord()
                currentBreak.append(scalar)
            } else {
                emitBreak()
                currentWord.append(scalar)
            }
        }

        // Only one of these will actually do anything based on whether our last char was whitespace or not.
        emitWord()
        emitBreak()
    }

    func visitStringSegment(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
        // Looks up the correct break kind based on prior context.
        let stringLiteralParent =
            node.parent?
            .as(StringLiteralSegmentListSyntax.self)?
            .parent?
            .as(StringLiteralExprSyntax.self)
        let breakKind =
            stringLiteralParent.map {
                pendingMultilineStringBreakKinds[$0, default: .same]
            } ?? .same

        let isMultiLineString =
            stringLiteralParent?.openingQuote.tokenKind == .multilineStringQuote
            // We don't reflow raw strings, so treat them as if they weren't multiline
            && stringLiteralParent?.openingPounds == nil

        let emitSegmentTextTokens =
            // If our configure reflow behavior is never, always use the single line emit segment text tokens.
            isMultiLineString && !config[ReflowMultilineStringLiterals.self].isNever
            ? { (segment) in
                self.emitMultilineSegmentTextTokens(breakKind: breakKind, segment: segment)
            }
            // For single line strings we don't allow line breaks, so emit the string as a single `.syntax` token
            : { (segment) in self.appendToken(.syntax(String(segment))) }

        let segmentText = node.content.text
        if segmentText.hasSuffix("\n") {
            // If this is a multiline string segment, it will end in a newline. Remove the newline and
            // append the rest of the string, followed by a break if it's not the last line before the
            // closing quotes. (The `StringLiteralExpr` above does the closing break.)
            let remainder = node.content.text.dropLast()

            if !remainder.isEmpty {
                // Replace each space in the segment text by an elective break of size 1
                emitSegmentTextTokens(remainder)
            }
            appendToken(.break(breakKind, newlines: .hard(count: 1)))
        } else {
            emitSegmentTextTokens(segmentText[...])
        }

        if !config[ReflowMultilineStringLiterals.self].isAlways,
            let continuation = node.trailingTrivia.multilineStringContinuation
        {
            // Segments with trailing backslashes won't end with a literal newline; the backslash and any
            // `#` delimiters for raw strings are considered trivia. To preserve the original text and
            // wrapping, we need to manually render them break into the token stream.
            appendToken(.syntax(continuation))
            appendToken(.break(breakKind, newlines: .hard(count: 1)))
        }
        return .skipChildren
    }
}
