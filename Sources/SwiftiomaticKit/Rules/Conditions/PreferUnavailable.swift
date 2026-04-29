import SwiftSyntax

/// Prefer `#unavailable(...)` over `#available(...) {} else { ... }`.
///
/// Inverting an availability check via an empty `if`-body and a non-empty `else`-body is harder to
/// read than the direct `#unavailable` form (Swift 5.6+). This rule rewrites the simple shape; it
/// does not touch chains where the `else` body has its own availability check (rewriting those is
/// not a simple inversion).
///
/// Lint: A warning is raised on `if #available(iOS X, *) {} else { body }`.
///
/// Rewrite: The `if` is rewritten to `if #unavailable(iOS X, *) { body }`.
final class PreferUnavailable: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    static func transform(
        _ node: IfExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let ifExpr = node
        guard ifExpr.body.statements.isEmpty,
            let onlyCondition = ifExpr.conditions.firstAndOnly,
            case .availability(let availability) = onlyCondition.condition,
            let elseBody = ifExpr.elseBody,
            case .codeBlock(let elseBlock) = elseBody,
            !elseAvailabilityCheckChainInvolved(elseBlock)
        else { return ExprSyntax(ifExpr) }

        let isAvailable = availability.availabilityKeyword.tokenKind == .poundAvailable
        let isUnavailable = availability.availabilityKeyword.tokenKind == .poundUnavailable
        guard isAvailable || isUnavailable else { return ExprSyntax(ifExpr) }

        Self.diagnose(
            .preferUnavailable(currentlyAvailable: isAvailable),
            on: availability,
            context: context
        )

        // Build the inverted availability keyword.
        let newKeyword: TokenSyntax =
            isAvailable
            ? .poundUnavailableToken(
                leadingTrivia: availability.availabilityKeyword.leadingTrivia,
                trailingTrivia: availability.availabilityKeyword.trailingTrivia
            )
            : .poundAvailableToken(
                leadingTrivia: availability.availabilityKeyword.leadingTrivia,
                trailingTrivia: availability.availabilityKeyword.trailingTrivia
            )
        let newAvailability = availability.with(\.availabilityKeyword, newKeyword)

        // Rebuild the condition list with the swapped keyword.
        var newCondition = onlyCondition
        newCondition.condition = .availability(newAvailability)
        let newConditions = ConditionElementListSyntax([newCondition])

        // Move the else body into the if body, dropping the else clause entirely. The original
        // if-body's left brace had a trailing space before its empty body; keep the elseBlock's
        // own brace trivia (which already represents the proper indentation), and just preserve
        // the original `if {`'s left-brace leading trivia.
        var newBody = elseBlock
        newBody.leftBrace = newBody.leftBrace.with(
            \.leadingTrivia, ifExpr.body.leftBrace.leadingTrivia
        )

        var result = ifExpr
        result.conditions = newConditions
        result.body = newBody
        result.elseKeyword = nil
        result.elseBody = nil
        return ExprSyntax(result)
    }

    /// True when the else body itself contains another `if`-with-availability — we don't rewrite
    /// chained availability ladders.
    private static func elseAvailabilityCheckChainInvolved(_ elseBlock: CodeBlockSyntax) -> Bool {
        // The classic pattern is `else if #available(...)`; in syntax that becomes a code block
        // with a single ExpressionStmt wrapping an IfExpr. We're conservative: any `if` with any
        // availability condition somewhere in its conditions disqualifies the rewrite.
        for item in elseBlock.statements {
            if let exprStmt = item.item.as(ExpressionStmtSyntax.self),
                let ifExpr = exprStmt.expression.as(IfExprSyntax.self),
                hasAvailabilityCondition(ifExpr)
            {
                return true
            }
        }
        return false
    }

    private static func hasAvailabilityCondition(_ ifExpr: IfExprSyntax) -> Bool {
        for condition in ifExpr.conditions {
            if case .availability = condition.condition { return true }
        }
        if case .ifExpr(let nested) = ifExpr.elseBody {
            return hasAvailabilityCondition(nested)
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static func preferUnavailable(currentlyAvailable: Bool) -> Finding.Message {
        if currentlyAvailable {
            return "use '#unavailable' instead of '#available' with an empty body"
        }
        return "use '#available' instead of '#unavailable' with an empty body"
    }
}
