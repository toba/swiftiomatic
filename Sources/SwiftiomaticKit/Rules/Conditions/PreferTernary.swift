import SwiftSyntax

/// Use ternary conditional expressions for simple if-else returns or assignments.
///
/// When an `if` - `else` has exactly two branches, each containing a single `return` statement or a
/// single assignment to the same variable, and the condition is a simple expression (no else-if
/// chains), the construct is collapsed into a ternary conditional expression.
///
/// ```swift
/// // Before
/// if condition {
///     return trueValue
/// } else {
///     return falseValue
/// }
/// // After
/// return condition ? trueValue : falseValue
///
/// // Before
/// if condition {
///     result = trueValue
/// } else {
///     result = falseValue
/// }
/// // After
/// result = condition ? trueValue : falseValue
/// ```
///
/// Lint: A simple if-else with single returns or same-variable assignments in both branches raises
/// a warning.
///
/// Rewrite: The if-else is replaced with a ternary expression.
final class PreferTernary: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ visited: CodeBlockItemListSyntax,
        parent: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        let items = Array(visited)
        var newItems = [CodeBlockItemSyntax]()
        var changed = false
        var index = 0

        while index < items.count {
            let item = items[index]
            let next = index + 1 < items.count ? items[index + 1] : nil

            if let next, let replacement = tryConvertIfReturnPair(item, next, context: context) {
                newItems.append(replacement)
                changed = true
                index += 2
                continue
            }

            if let replacement = tryConvert(item, context: context) {
                newItems.append(replacement)
                changed = true
            } else {
                newItems.append(item)
            }
            index += 1
        }

        guard changed else { return visited }
        return CodeBlockItemListSyntax(newItems)
    }

    // MARK: - Conversion

    private static func tryConvert(
        _ item: CodeBlockItemSyntax,
        context: Context
    ) -> CodeBlockItemSyntax? {
        guard let ifExpr = extractIfExpr(from: item) else { return nil }

        // Must be a simple if-else (no else-if chains)
        guard let elseBlock = ifExpr.elseBody?.as(CodeBlockSyntax.self) else { return nil }

        // Condition must be a single boolean expression (not optional binding, pattern matching,
        // availability check, etc.)
        guard let onlyCondition = ifExpr.conditions.firstAndOnly,
              case .expression = onlyCondition.condition else { return nil }

        let thenStatements = ifExpr.body.statements
        let elseStatements = elseBlock.statements

        // Each branch must have exactly one statement
        guard let thenOnly = thenStatements.firstAndOnly,
              let elseOnly = elseStatements.firstAndOnly else { return nil }

        // Both branches are return statements
        if let thenReturn = extractReturn(from: thenOnly),
           let elseReturn = extractReturn(from: elseOnly)
        {
            return buildTernaryReturn(
                item: item,
                ifExpr: ifExpr,
                thenExpr: thenReturn,
                elseExpr: elseReturn,
                context: context)
        }

        // Both branches assign to the same variable
        if let (lhs, thenRHS) = extractAssignment(from: thenOnly),
           let (elseLHS, elseRHS) = extractAssignment(from: elseOnly),
           lhs.trimmedDescription == elseLHS.trimmedDescription
        {
            return buildTernaryAssignment(
                item: item,
                ifExpr: ifExpr,
                lhs: lhs,
                thenExpr: thenRHS,
                elseExpr: elseRHS,
                context: context)
        }

        return nil
    }

    /// Converts `if cond { return X }` followed by `return Y` into `return cond ? X : Y` .
    private static func tryConvertIfReturnPair(
        _ first: CodeBlockItemSyntax,
        _ second: CodeBlockItemSyntax,
        context: Context
    ) -> CodeBlockItemSyntax? {
        guard let ifExpr = extractIfExpr(from: first) else { return nil }
        guard ifExpr.elseBody == nil else { return nil }

        guard let onlyCondition = ifExpr.conditions.firstAndOnly,
              case .expression = onlyCondition.condition else { return nil }

        guard let thenOnly = ifExpr.body.statements.firstAndOnly,
              let thenReturn = extractReturn(from: thenOnly) else { return nil }

        guard let elseReturn = extractReturn(from: second) else { return nil }

        Self.diagnose(.useTernary, on: ifExpr.ifKeyword, context: context)

        let ternary = buildTernaryExpr(
            condition: ifExpr.conditions,
            thenExpr: thenReturn,
            elseExpr: elseReturn,
            context: context)

        let returnStmt = ReturnStmtSyntax(
            returnKeyword: .keyword(.return, trailingTrivia: .space),
            expression: ternary)

        return .init(
            leadingTrivia: first.leadingTrivia,
            item: .stmt(StmtSyntax(returnStmt)),
            trailingTrivia: second.trailingTrivia)
    }

    // MARK: - Extraction

    private static func extractIfExpr(from item: CodeBlockItemSyntax) -> IfExprSyntax? {
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
            exprStmt.expression.as(IfExprSyntax.self)
        } else {
            item.item.as(IfExprSyntax.self)
        }
    }

    /// Extracts the expression from a `return expr` statement.
    private static func extractReturn(from item: CodeBlockItemSyntax) -> ExprSyntax? {
        if let returnStmt = item.item.as(ReturnStmtSyntax.self),
           let expr = returnStmt.expression
        {
            expr
        } else {
            nil
        }
    }

    /// Extracts the LHS and RHS from an assignment like `result = expr` .
    private static func extractAssignment(
        from item: CodeBlockItemSyntax
    ) -> (ExprSyntax, ExprSyntax)? {
        let expr: ExprSyntax?
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
            expr = exprStmt.expression
        } else {
            expr = item.item.as(ExprSyntax.self)
        }
        guard let infixExpr = expr?.as(InfixOperatorExprSyntax.self),
              infixExpr.operator.is(AssignmentExprSyntax.self) else { return nil }
        return (infixExpr.leftOperand, infixExpr.rightOperand)
    }

    // MARK: - Building ternary

    private static func buildTernaryReturn(
        item: CodeBlockItemSyntax,
        ifExpr: IfExprSyntax,
        thenExpr: ExprSyntax,
        elseExpr: ExprSyntax,
        context: Context
    ) -> CodeBlockItemSyntax {
        Self.diagnose(.useTernary, on: ifExpr.ifKeyword, context: context)

        let ternary = buildTernaryExpr(
            condition: ifExpr.conditions,
            thenExpr: thenExpr,
            elseExpr: elseExpr,
            context: context)

        let returnStmt = ReturnStmtSyntax(
            returnKeyword: .keyword(.return, trailingTrivia: .space),
            expression: ternary)

        return .init(
            leadingTrivia: item.leadingTrivia,
            item: .stmt(StmtSyntax(returnStmt)),
            trailingTrivia: item.trailingTrivia)
    }

    private static func buildTernaryAssignment(
        item: CodeBlockItemSyntax,
        ifExpr: IfExprSyntax,
        lhs: ExprSyntax,
        thenExpr: ExprSyntax,
        elseExpr: ExprSyntax,
        context: Context
    ) -> CodeBlockItemSyntax {
        Self.diagnose(.useTernary, on: ifExpr.ifKeyword, context: context)

        let ternary = buildTernaryExpr(
            condition: ifExpr.conditions,
            thenExpr: thenExpr,
            elseExpr: elseExpr,
            context: context)

        let assignment = InfixOperatorExprSyntax(
            leftOperand: lhs.with(\.leadingTrivia, []).with(\.trailingTrivia, .space),
            operator: ExprSyntax(
                AssignmentExprSyntax(
                    equal: .equalToken(trailingTrivia: .space))),
            rightOperand: ternary)

        return .init(
            leadingTrivia: item.leadingTrivia,
            item: .expr(ExprSyntax(assignment)),
            trailingTrivia: item.trailingTrivia)
    }

    private static func buildTernaryExpr(
        condition: ConditionElementListSyntax,
        thenExpr: ExprSyntax,
        elseExpr: ExprSyntax,
        context: Context
    ) -> ExprSyntax {
        // The caller already verified a single expression condition.
        let onlyCondition = condition.first!
        guard case let .expression(conditionExpr) = onlyCondition.condition
        else { return ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("false"))) }

        // Capture the original anchor column before detaching the condition, since
        // startLocation on a detached/synthesized node is unreliable.
        let anchorCol = conditionExpr.startLocation(converter: context.sourceLocationConverter).column

        var ternary = TernaryExprSyntax(
            condition: conditionExpr.with(\.trailingTrivia, .space),
            questionMark: .infixQuestionMarkToken(trailingTrivia: .space),
            thenExpression: thenExpr.with(\.leadingTrivia, []).with(\.trailingTrivia, .space),
            colon: .colonToken(trailingTrivia: .space),
            elseExpression: elseExpr.with(\.leadingTrivia, []).with(\.trailingTrivia, []))

        // The synthesized ternary is built inside a CodeBlockItemList rewrite, so the
        // SyntaxRewriter never descends into it and WrapTernary's TernaryExpr visitor
        // never fires. Mirror its policy here using the captured anchor column so both
        // branches wrap together when the result would exceed the line length.
        let lineLength = context.configuration[LineLength.self]
        let singleLineLength = ternary.trimmedDescription
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ").count
        if (anchorCol - 1) + singleLineLength > lineLength {
            ternary.questionMark.leadingTrivia = .newline + ternary.questionMark.leadingTrivia
            ternary.colon.leadingTrivia = .newline + ternary.colon.leadingTrivia
        }

        return ExprSyntax(ternary)
    }
}

fileprivate extension Finding.Message {
    static let useTernary: Finding.Message = "use ternary conditional expression for simple if-else"
}
