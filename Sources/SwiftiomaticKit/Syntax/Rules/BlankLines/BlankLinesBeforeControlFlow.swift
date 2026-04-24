import SwiftSyntax

/// Insert a blank line before control flow statements with multi-line bodies.
///
/// When a `for`, `while`, `repeat`, `if`, `switch`, `do`, or `defer` statement has a
/// multi-line body and is preceded by another statement, a blank line before it improves
/// readability. Single-line (inline) control flow is excluded. Guard statements are excluded
/// because `BlankLinesAfterGuardStatements` already handles spacing around guards.
///
/// Lint: If a multi-line control flow statement is not preceded by a blank line, a lint
///       warning is raised.
///
/// Format: A blank line is inserted before the control flow statement.
final class BlankLinesBeforeControlFlow: RewriteSyntaxRule<BasicRuleValue> {
    override static var key: String { "beforeControlFlow" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        let originalItems = Array(node.statements)
        let visited = super.visit(node)
        guard let statements = insertBlankLines(
            in: originalItems, visited: Array(visited.statements)
        ) else { return visited }
        var result = visited
        result.statements = CodeBlockItemListSyntax(statements)
        return result
    }

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        let originalItems = Array(node.statements)
        let visited = super.visit(node)
        guard let statements = insertBlankLines(
            in: originalItems, visited: Array(visited.statements)
        ) else { return visited }
        var result = visited
        result.statements = CodeBlockItemListSyntax(statements)
        return result
    }

    // MARK: - Blank line insertion

    private func insertBlankLines(
        in originalItems: [CodeBlockItemSyntax],
        visited visitedItems: [CodeBlockItemSyntax]
    ) -> [CodeBlockItemSyntax]? {
        var statements = visitedItems
        var modified = false

        let braceIsBlank = context.configuration[ClosingBraceAsBlankLine.self]

        for i in 1..<visitedItems.count {
            let item = visitedItems[i]
            guard isMultiLineControlFlow(item.item) else { continue }
            guard !item.leadingTrivia.hasBlankLine else { continue }
            if braceIsBlank, endsSolitaryBrace(visitedItems[i - 1]) { continue }

            diagnose(.insertBlankLineBeforeControlFlow, on: originalItems[i].item)
            var next = item
            next.leadingTrivia = .newline + item.leadingTrivia
            statements[i] = next
            modified = true
        }

        return modified ? statements : nil
    }

    // MARK: - Helpers

    /// Whether the item's last token is `}` on its own line.
    private func endsSolitaryBrace(_ item: CodeBlockItemSyntax) -> Bool {
        guard let lastToken = item.lastToken(viewMode: .sourceAccurate),
            lastToken.tokenKind == .rightBrace
        else { return false }
        return lastToken.leadingTrivia.containsNewlines
    }

    private func isMultiLineControlFlow(_ item: CodeBlockItemSyntax.Item) -> Bool {
        switch item {
            case .stmt(let stmt):
                if let forStmt = stmt.as(ForStmtSyntax.self) {
                    return isMultiLineBody(forStmt.body)
                }
                if let whileStmt = stmt.as(WhileStmtSyntax.self) {
                    return isMultiLineBody(whileStmt.body)
                }
                if let repeatStmt = stmt.as(RepeatStmtSyntax.self) {
                    return isMultiLineBody(repeatStmt.body)
                }
                if let doStmt = stmt.as(DoStmtSyntax.self) { return isMultiLineBody(doStmt.body) }
                if let deferStmt = stmt.as(DeferStmtSyntax.self) {
                    return isMultiLineBody(deferStmt.body)
                }
                // if/switch are expressions wrapped in ExpressionStmtSyntax
                if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
                    return isMultiLineControlFlowExpr(exprStmt.expression)
                }
                return false
            case .expr(let expr):
                return isMultiLineControlFlowExpr(expr)
            default:
                return false
        }
    }

    private func isMultiLineControlFlowExpr(_ expr: ExprSyntax) -> Bool {
        if let ifExpr = expr.as(IfExprSyntax.self) { return isMultiLineBody(ifExpr.body) }

        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return switchExpr.rightBrace.leadingTrivia.containsNewlines
        }
        return false
    }

    private func isMultiLineBody(_ body: CodeBlockSyntax) -> Bool {
        body.rightBrace.leadingTrivia.containsNewlines
    }
}

extension Finding.Message {
    fileprivate static let insertBlankLineBeforeControlFlow: Finding.Message =
        "insert blank line before control flow statement"
}
