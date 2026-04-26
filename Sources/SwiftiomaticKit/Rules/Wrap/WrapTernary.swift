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
final class WrapTernary: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .lineBreaks }

    override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
        let visited = super.visit(node).cast(TernaryExprSyntax.self)

        let questionHasNewline = visited.questionMark.leadingTrivia.containsNewlines
        let colonHasNewline = visited.colon.leadingTrivia.containsNewlines

        let needsWrap: Bool
        if questionHasNewline || colonHasNewline {
            needsWrap = true
        } else {
            let length = singleLineLength(of: visited)
            let lineLength = context.configuration[LineLength.self]
            // Nested ternaries (those inside another ternary) only wrap when their intrinsic length
            // exceeds the line length on its own. Their actual column after the parent wraps is
            // not knowable here, and using the raw source column would over-wrap.
            if hasAncestorTernary(visited) {
                needsWrap = length > lineLength
            } else {
                let converter = context.sourceLocationConverter
                let startCol = visited.condition.startLocation(converter: converter).column
                needsWrap = (startCol - 1) + length > lineLength
            }
        }

        guard needsWrap else { return ExprSyntax(visited) }

        var result = visited
        if !questionHasNewline {
            diagnose(.wrapTernaryBranch, on: visited.questionMark)
            result.questionMark.leadingTrivia = .newline + dropLeadingSpaces(result.questionMark.leadingTrivia)
        }
        if !colonHasNewline {
            diagnose(.wrapTernaryBranch, on: visited.colon)
            result.colon.leadingTrivia = .newline + dropLeadingSpaces(result.colon.leadingTrivia)
        }
        return ExprSyntax(result)
    }

    /// Strips a single leading run of horizontal whitespace from a trivia sequence so we
    /// don't end up with a redundant space after the inserted newline. The pretty printer
    /// recomputes indentation regardless.
    private func dropLeadingSpaces(_ trivia: Trivia) -> Trivia {
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
    private func singleLineLength(of node: TernaryExprSyntax) -> Int {
        node.trimmedDescription
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .count
    }

    /// True if `node` is contained within another `TernaryExprSyntax`.
    private func hasAncestorTernary(_ node: TernaryExprSyntax) -> Bool {
        var current = node.parent
        while let parent = current {
            if parent.is(TernaryExprSyntax.self) { return true }
            current = parent.parent
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let wrapTernaryBranch: Finding.Message =
        "wrap ternary branch onto a new line"
}
