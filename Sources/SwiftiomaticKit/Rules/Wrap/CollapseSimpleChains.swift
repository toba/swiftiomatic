import SwiftSyntax

/// Collapses a multi-line member-access chain onto a single line when the collapsed form fits
/// within the configured line length.
///
/// ```swift
/// // Before
/// try SyncRemindersList
///     .find(1)
///     .delete(from: db)
///
/// // After
/// try SyncRemindersList.find(1).delete(from: db)
/// ```
///
/// Lint: A multi-line chain where the collapsed form fits within line length raises a warning.
///
/// Rewrite: The chain is collapsed onto a single line.
final class CollapseSimpleChains: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func apply(
        _ node: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        context: Context
    ) -> FunctionCallExprSyntax {
        guard !isInnerChainCall(ExprSyntax(node)) else { return node }

        var periods = [TokenSyntax]()
        collectPeriods(ExprSyntax(node), into: &periods)

        let wrappedPeriods = periods.filter { $0.leadingTrivia.containsNewlines }
        guard !wrappedPeriods.isEmpty else { return node }

        let periodIDs = Set(wrappedPeriods.map(\.id))

        // Bail if any trivia in the chain contains comments or unexpected inner newlines.
        // Also bail if the first token has a leading newline — its column would be wrong for
        // the line-length check (e.g. `let x =\n    foo\n    .bar()`).
        var isFirst = true
        for token in ExprSyntax(node).tokens(viewMode: .sourceAccurate) {
            let leading = token.leadingTrivia
            let trailing = token.trailingTrivia
            if leading.hasAnyComments || trailing.hasAnyComments { return node }
            if leading.containsNewlines, isFirst || !periodIDs.contains(token.id) { return node }
            isFirst = false
        }

        let maxLength = context.configuration[LineLength.self]
        let startColumn = original.firstToken(viewMode: .sourceAccurate)?
            .startLocation(converter: context.sourceLocationConverter).column ?? 1
        let chainLength = collapsedLength(of: ExprSyntax(node), strippingPeriods: periodIDs)
        guard (startColumn - 1) + chainLength <= maxLength else { return node }

        Self.diagnose(.collapseChain, on: node, context: context)

        let rewriter = ChainPeriodRewriter(targetIDs: periodIDs)
        return rewriter.rewrite(Syntax(node)).as(FunctionCallExprSyntax.self) ?? node
    }
}

// MARK: - Chain Walking

extension CollapseSimpleChains {
    fileprivate static func collectPeriods(_ expr: ExprSyntax, into periods: inout [TokenSyntax]) {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            collectPeriods(call.calledExpression, into: &periods)
        } else if let sub = expr.as(SubscriptCallExprSyntax.self) {
            collectPeriods(sub.calledExpression, into: &periods)
        } else if let member = expr.as(MemberAccessExprSyntax.self) {
            periods.append(member.period)
            if let base = member.base { collectPeriods(base, into: &periods) }
        } else if let optional = expr.as(OptionalChainingExprSyntax.self) {
            collectPeriods(optional.expression, into: &periods)
        } else if let force = expr.as(ForceUnwrapExprSyntax.self) {
            collectPeriods(force.expression, into: &periods)
        }
    }

    fileprivate static func isInnerChainCall(_ expr: ExprSyntax) -> Bool {
        guard let parent = expr.parent else { return false }
        // If the parent is MemberAccessExpr the chain extends above this call — bail
        // so we don't partially collapse and leave a dangling member on the next line.
        if parent.as(MemberAccessExprSyntax.self) != nil { return true }
        return parent.as(OptionalChainingExprSyntax.self) != nil
            || parent.as(ForceUnwrapExprSyntax.self) != nil
    }

    fileprivate static func collapsedLength(
        of expr: ExprSyntax,
        strippingPeriods periodIDs: Set<SyntaxIdentifier>
    ) -> Int {
        var length = 0
        for token in expr.tokens(viewMode: .sourceAccurate) {
            let leadingLen = periodIDs.contains(token.id)
                ? 0
                : token.leadingTrivia.description.count
            length += leadingLen + token.text.count + token.trailingTrivia.description.count
        }
        return length
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let collapseChain: Finding.Message = "collapse chained calls onto a single line"
}

// MARK: - Rewriter

private final class ChainPeriodRewriter: SyntaxRewriter {
    let targetIDs: Set<SyntaxIdentifier>

    init(targetIDs: Set<SyntaxIdentifier>) { self.targetIDs = targetIDs }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        targetIDs.contains(token.id) ? token.with(\.leadingTrivia, []) : token
    }
}
