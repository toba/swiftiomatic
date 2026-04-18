import SwiftSyntax

/// Chained function calls are wrapped consistently: if any dot in the chain
/// is on a different line, all dots are placed on separate lines.
///
/// Lint: A multiline chain where some dots share a line raises a warning.
///
/// Format: Dots that share a line with a closing scope or another dot are
///         moved to their own line.
final class WrapMultilineFunctionChains: SyntaxFormatRule {
    static let group: ConfigGroup? = .wrap
    static let isOptIn = true

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let callNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

        // Only process the outermost call in a chain.
        if isInnerChainCall(ExprSyntax(callNode)) { return visited }

        // Collect all periods and metadata from the chain
        var periods = [TokenSyntax]()
        var hasFunctionCall = false
        collectChain(ExprSyntax(callNode), periods: &periods, hasFunctionCall: &hasFunctionCall)

        // Reverse so periods are in source order (collectChain collects outermost first)
        periods.reverse()

        // Need at least 2 dots and at least 1 function call
        guard periods.count > 1, hasFunctionCall else { return visited }

        // All dots on the same line → single-line chain, skip
        let hasNewline = periods.contains { $0.leadingTrivia.containsNewlines }
        guard hasNewline else { return visited }

        // Find periods that need wrapping using SwiftFormat's approach:
        // For each dot, check if a closing scope (`}`, `)`, `]`) immediately
        // precedes it on the same line — if so, that dot needs its own line.
        // Also check if the next dot in the chain is on the same line — if so,
        // the next dot needs its own line.
        var periodsToWrap = Set<SyntaxIdentifier>()
        for (i, period) in periods.enumerated() {
            if period.leadingTrivia.containsNewlines { continue }
            if isTypeAccess(after: period) { continue }

            // Case 1: closing scope precedes this dot on the same line
            if let prev = previousNonSpaceToken(before: period), isClosingScope(prev) {
                periodsToWrap.insert(period.id)
                continue
            }

            // Case 2: the next dot is on the same line as this dot — wrap the
            // next dot (split two dots that share a line)
            if i + 1 < periods.count {
                let nextPeriod = periods[i + 1]
                if !nextPeriod.leadingTrivia.containsNewlines,
                    !isTypeAccess(after: nextPeriod)
                {
                    // Two consecutive dots on the same line in a multiline chain
                    periodsToWrap.insert(nextPeriod.id)
                }
            }
        }

        // Convert IDs back to tokens in source order
        let orderedToWrap = periods.filter { periodsToWrap.contains($0.id) }

        guard !orderedToWrap.isEmpty else { return visited }

        // Determine indentation from an existing wrapped period
        let indent: String =
            periods.first { $0.leadingTrivia.containsNewlines }?
            .leadingTrivia.indentation ?? "    "

        diagnose(.wrapChain, on: orderedToWrap[0])

        var result = ExprSyntax(callNode)
        for period in orderedToWrap {
            result = replacePeriodTrivia(
                in: result,
                period: period,
                newTrivia: .newline + Trivia(stringLiteral: indent)
            )
        }

        return result
    }

    // MARK: - Chain collection

    /// Recursively walks the chain from outermost call to base, collecting
    /// all `.period` tokens and tracking whether function calls exist.
    private func collectChain(
        _ expr: ExprSyntax,
        periods: inout [TokenSyntax],
        hasFunctionCall: inout Bool
    ) {
        if let callExpr = expr.as(FunctionCallExprSyntax.self) {
            hasFunctionCall = true
            collectChain(
                callExpr.calledExpression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let subscriptExpr = expr.as(SubscriptCallExprSyntax.self) {
            hasFunctionCall = true
            collectChain(
                subscriptExpr.calledExpression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            periods.append(memberAccess.period)
            if let base = memberAccess.base {
                collectChain(base, periods: &periods, hasFunctionCall: &hasFunctionCall)
            }
        } else if let optionalChain = expr.as(OptionalChainingExprSyntax.self) {
            collectChain(
                optionalChain.expression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let forceUnwrap = expr.as(ForceUnwrapExprSyntax.self) {
            collectChain(
                forceUnwrap.expression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        }
    }

    /// Returns `true` if this call is an inner node of a larger chain.
    private func isInnerChainCall(_ expr: ExprSyntax) -> Bool {
        guard let parent = expr.parent else { return false }
        if parent.as(MemberAccessExprSyntax.self) != nil {
            if let grandparent = parent.parent,
                grandparent.is(FunctionCallExprSyntax.self)
                    || grandparent.is(SubscriptCallExprSyntax.self)
            {
                return true
            }
        }
        if parent.as(OptionalChainingExprSyntax.self) != nil
            || parent.as(ForceUnwrapExprSyntax.self) != nil
        {
            return true
        }
        return false
    }

    // MARK: - Helpers

    /// Returns the previous non-space/comment token before the given token.
    private func previousNonSpaceToken(before token: TokenSyntax) -> TokenSyntax? {
        var current = token.previousToken(viewMode: .sourceAccurate)
        while let tok = current {
            // Skip space-only trivia tokens — in swift-syntax, spaces between
            // tokens are in trivia, not separate tokens. But we need to handle
            // the case where the period's leading trivia has spaces.
            return tok
        }
        return nil
    }

    /// Returns the next period in the collected chain after the given period.
    private func nextPeriodInChain(after period: TokenSyntax, in periods: [TokenSyntax])
        -> TokenSyntax?
    {
        guard let idx = periods.firstIndex(where: { $0.id == period.id }),
            idx + 1 < periods.count
        else { return nil }
        return periods[idx + 1]
    }

    /// Returns `true` if the token is a closing scope (`)`, `}`, `]`).
    private func isClosingScope(_ token: TokenSyntax) -> Bool {
        switch token.tokenKind {
        case .rightParen, .rightBrace, .rightSquare: return true
        default: return false
        }
    }

    /// Returns `true` if the token after the period is a capitalized identifier.
    private func isTypeAccess(after period: TokenSyntax) -> Bool {
        guard let next = period.nextToken(viewMode: .sourceAccurate),
            case .identifier(let name) = next.tokenKind,
            let first = name.first, first.isUppercase
        else { return false }
        return true
    }

    /// Replaces the leading trivia of a specific period token.
    private func replacePeriodTrivia(
        in expr: ExprSyntax,
        period: TokenSyntax,
        newTrivia: Trivia
    ) -> ExprSyntax {
        let rewriter = PeriodTriviaRewriter(targetID: period.id, newTrivia: newTrivia)
        return rewriter.rewrite(Syntax(expr)).cast(ExprSyntax.self)
    }
}

/// Replaces leading trivia on a specific token.
private class PeriodTriviaRewriter: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrivia: Trivia

    init(targetID: SyntaxIdentifier, newTrivia: Trivia) {
        self.targetID = targetID
        self.newTrivia = newTrivia
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if token.id == targetID {
            return token.with(\.leadingTrivia, newTrivia)
        }
        return token
    }
}

extension Finding.Message {
    fileprivate static let wrapChain: Finding.Message =
        "wrap multiline function chain consistently"
}
