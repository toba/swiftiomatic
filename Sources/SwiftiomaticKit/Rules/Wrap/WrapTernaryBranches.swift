import SwiftSyntax

/// Wrap each branch of a ternary expression onto its own line when the expression
/// would exceed the configured line length.
///
/// The pretty printer no longer makes wrapping decisions for ternaries — instead, this
/// rule inserts discretionary newlines into the leading trivia of `?` and `:` whenever
/// the ternary's last column would exceed `LineLength`. The pretty printer respects
/// those newlines (see `RespectExistingLineBreaks`) and applies a continuation indent
/// to each wrapped branch, producing:
///
/// ```swift
/// pendingLeadingTrivia = trailingNonSpace.isEmpty
///   ? token.leadingTrivia
///   : token.leadingTrivia + trailingNonSpace
/// ```
///
/// If either operator already has a leading newline, the rule normalizes the other to
/// match so the ternary always has both branches on their own lines once it wraps.
final class WrapTernaryBranches: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .lineBreaks }

    static func transform(
        _ visited: TernaryExprSyntax,
        original: TernaryExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Inserting newlines around `?`/`:` inside a single-line string interpolation
        // produces invalid Swift (newlines aren't allowed inside `"\(...)"`).
        if isInsideSingleLineStringInterpolation(parent: parent) {
            return ExprSyntax(visited)
        }

        let questionHasNewline = visited.questionMark.leadingTrivia.containsNewlines
        let colonHasNewline = visited.colon.leadingTrivia.containsNewlines

        let needsWrap: Bool
        if questionHasNewline || colonHasNewline {
            needsWrap = true
        } else {
            let lineLength = context.configuration[LineLength.self]
            let converter = context.sourceLocationConverter

            // If the source lines that already host `?` and `:` both fit within the print width,
            // the ternary's operators are already on lines that don't overflow — no need to force
            // a wrap, even if the *collapsed-to-one-line* description of the ternary is long.
            // This matters when an operand is consumed by a lower-precedence operator that wraps
            // independently (e.g. `cond ? a : b + multiLineChain` parses as `cond ? a : (b + …)`,
            // making the else branch span multiple lines while `?` and `:` stay on one short line).
            let questionLineFits = sourceLineLength(at: original.questionMark, converter: converter)
                .map { $0 <= lineLength } ?? false
            let colonLineFits = sourceLineLength(at: original.colon, converter: converter)
                .map { $0 <= lineLength } ?? false
            if questionLineFits, colonLineFits {
                needsWrap = false
            } else {
                let length = singleLineLength(of: visited)
                // Nested ternaries (those inside another ternary) only wrap when their intrinsic
                // length exceeds the line length on its own. Their actual column after the parent
                // wraps is not knowable here, and using the raw source column would over-wrap.
                if hasAncestorTernary(parent: parent) {
                    needsWrap = length > lineLength
                } else {
                    let startCol = visited.condition.startLocation(converter: converter).column
                    needsWrap = (startCol - 1) + length > lineLength
                }
            }
        }

        guard needsWrap else { return ExprSyntax(visited) }

        var result = visited
        if !questionHasNewline {
            Self.diagnose(.wrapTernaryBranch, on: original.questionMark, context: context)
            result.questionMark.leadingTrivia = .newline + dropLeadingSpaces(result.questionMark.leadingTrivia)
        }
        if !colonHasNewline {
            Self.diagnose(.wrapTernaryBranch, on: original.colon, context: context)
            result.colon.leadingTrivia = .newline + dropLeadingSpaces(result.colon.leadingTrivia)
        }
        return ExprSyntax(result)
    }

    /// Strips a single leading run of horizontal whitespace from a trivia sequence so we
    /// don't end up with a redundant space after the inserted newline. The pretty printer
    /// recomputes indentation regardless.
    private static func dropLeadingSpaces(_ trivia: Trivia) -> Trivia {
        guard let first = trivia.first else { return trivia }
        switch first {
        case .spaces, .tabs:
            return Trivia(pieces: Array(trivia.dropFirst()))
        default:
            return trivia
        }
    }

    /// Returns the length of the ternary as if it were rendered on a single line — collapsing any
    /// internal newlines or multi-space runs to single spaces.
    private static func singleLineLength(of node: TernaryExprSyntax) -> Int {
        node.trimmedDescription
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .count
    }

    /// True if `node` is contained within an `ExpressionSegmentSyntax` whose enclosing
    /// `StringLiteralExprSyntax` is single-line (i.e. not a `"""..."""` literal). Inserting
    /// newlines into such a context produces invalid Swift.
    private static func isInsideSingleLineStringInterpolation(parent: Syntax?) -> Bool {
        var current = parent
        while let p = current {
            if p.is(ExpressionSegmentSyntax.self) {
                var s: Syntax? = p.parent
                while let sp = s {
                    if let lit = sp.as(StringLiteralExprSyntax.self) {
                        return lit.openingQuote.tokenKind != .multilineStringQuote
                    }
                    s = sp.parent
                }
                return true
            }
            current = p.parent
        }
        return false
    }

    /// Returns the UTF-8 length of the source line that contains `token` (excluding the trailing
    /// newline). Returns `nil` if the line couldn't be measured.
    private static func sourceLineLength(
        at token: TokenSyntax,
        converter: SourceLocationConverter
    ) -> Int? {
        let line = token.startLocation(converter: converter).line
        let lineStart = converter.position(ofLine: line, column: 1).utf8Offset
        let nextLineStart = converter.position(ofLine: line + 1, column: 1).utf8Offset
        if nextLineStart > lineStart {
            // Subtract one for the trailing newline. The pretty-print line length is character-
            // based; for ASCII-heavy Swift source UTF-8 length is a safe upper bound.
            return nextLineStart - lineStart - 1
        }
        // Last line of the file (no trailing newline) — fall back to source-file end.
        let endOffset = token.root.endPosition.utf8Offset
        return endOffset >= lineStart ? endOffset - lineStart : nil
    }

    /// True if `node` is contained within another `TernaryExprSyntax`.
    /// Walks the captured pre-recursion parent chain since the post-recursion node is detached.
    private static func hasAncestorTernary(parent: Syntax?) -> Bool {
        var current = parent
        while let p = current {
            if p.is(TernaryExprSyntax.self) { return true }
            current = p.parent
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let wrapTernaryBranch: Finding.Message =
        "wrap ternary branch onto a new line"
}
