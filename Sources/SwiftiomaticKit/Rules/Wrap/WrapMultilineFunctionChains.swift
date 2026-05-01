import SwiftSyntax

/// Chained function calls are wrapped consistently: if any dot in the chain is on a different line,
/// all dots are placed on separate lines.
///
/// Lint: A multiline chain where some dots share a line raises a warning.
///
/// Rewrite: Dots that share a line with a closing scope or another dot are moved to their own line.
final class WrapMultilineFunctionChains: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Wrap dots in a multiline call chain so each one is on its own line. Called from
    /// `CompactSyntaxRewriter.visit(_: FunctionCallExprSyntax)` .
    static func apply(
        _ node: FunctionCallExprSyntax,
        context: Context
    ) -> FunctionCallExprSyntax {
        if isInnerChainCall(ExprSyntax(node)) { return node }

        var periods = [TokenSyntax]()
        var hasFunctionCall = false
        collectPeriods(
            ExprSyntax(node),
            periods: &periods,
            hasFunctionCall: &hasFunctionCall
        )
        periods.reverse()

        guard periods.count > 1, hasFunctionCall else { return node }

        let hasNewline = periods.contains { $0.leadingTrivia.containsNewlines }
        guard hasNewline else { return node }

        var periodsToWrap = Set<SyntaxIdentifier>()

        for (i, period) in periods.enumerated() {
            if period.leadingTrivia.containsNewlines { continue }
            if isTypeAccess(after: period) { continue }

            if let prev = period.previousToken(viewMode: .sourceAccurate),
               isClosingScope(prev)
            {
                periodsToWrap.insert(period.id)
                continue
            }

            if i + 1 < periods.count {
                let nextPeriod = periods[i + 1]

                if !nextPeriod.leadingTrivia.containsNewlines,
                   !isTypeAccess(after: nextPeriod)
                {
                    periodsToWrap.insert(nextPeriod.id)
                }
            }
        }

        let orderedToWrap = periods.filter { periodsToWrap.contains($0.id) }
        guard !orderedToWrap.isEmpty else { return node }

        let indent: String = periods.first { $0.leadingTrivia.containsNewlines }?.leadingTrivia
            .indentation ?? "    "

        Self.diagnose(.wrapChain, on: orderedToWrap[0], context: context)

        var resultExpr = ExprSyntax(node)

        for period in orderedToWrap {
            let rewriter = PeriodTriviaRewriter(
                targetID: period.id,
                newTrivia: .newline + Trivia(stringLiteral: indent)
            )
            resultExpr = rewriter.rewrite(Syntax(resultExpr)).cast(ExprSyntax.self)
        }
        return resultExpr.as(FunctionCallExprSyntax.self) ?? node
    }

    private static func collectPeriods(
        _ expr: ExprSyntax,
        periods: inout [TokenSyntax],
        hasFunctionCall: inout Bool
    ) {
        if let callExpr = expr.as(FunctionCallExprSyntax.self) {
            hasFunctionCall = true
            collectPeriods(
                callExpr.calledExpression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let subscriptExpr = expr.as(SubscriptCallExprSyntax.self) {
            hasFunctionCall = true
            collectPeriods(
                subscriptExpr.calledExpression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            periods.append(memberAccess.period)

            if let base = memberAccess.base {
                collectPeriods(
                    base,
                    periods: &periods,
                    hasFunctionCall: &hasFunctionCall
                )
            }
        } else if let optionalChain = expr.as(OptionalChainingExprSyntax.self) {
            collectPeriods(
                optionalChain.expression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        } else if let forceUnwrap = expr.as(ForceUnwrapExprSyntax.self) {
            collectPeriods(
                forceUnwrap.expression,
                periods: &periods,
                hasFunctionCall: &hasFunctionCall
            )
        }
    }

    private static func isInnerChainCall(_ expr: ExprSyntax) -> Bool {
        guard let parent = expr.parent else { return false }

        if parent.as(MemberAccessExprSyntax.self) != nil {
            if let grandparent = parent.parent,
               grandparent.is(FunctionCallExprSyntax.self)
                   || grandparent.is(SubscriptCallExprSyntax.self)
            {
                return true
            }
        }
        return parent.as(OptionalChainingExprSyntax.self) != nil
            || parent.as(ForceUnwrapExprSyntax.self) != nil
            ? true
            : false
    }

    private static func isClosingScope(_ token: TokenSyntax) -> Bool {
        switch token.tokenKind {
            case .rightParen, .rightBrace, .rightSquare: true
            default: false
        }
    }

    private static func isTypeAccess(after period: TokenSyntax) -> Bool {
        guard let next = period.nextToken(viewMode: .sourceAccurate),
              case let .identifier(name) = next.tokenKind,
              let first = name.first,
              first.isUppercase else { return false }
        return true
    }
}

fileprivate extension Finding.Message {
    static let wrapChain: Finding.Message = "wrap multiline function chain consistently"
}

private final class PeriodTriviaRewriter: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrivia: Trivia

    init(targetID: SyntaxIdentifier, newTrivia: Trivia) {
        self.targetID = targetID
        self.newTrivia = newTrivia
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        token.id == targetID ? token.with(\.leadingTrivia, newTrivia) : token
    }
}
