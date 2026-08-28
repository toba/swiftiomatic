import SwiftSyntax

/// Insert a blank line before control flow statements with multi-line bodies.
///
/// When a `for` , `while` , `repeat` , `if` , `switch` , `do` , or `defer` statement has a
/// multi-line body and is preceded by another statement, a blank line before it improves
/// readability. Single-line (inline) control flow is excluded. Guard statements are excluded
/// because `InsertBlankLineAfterGuard` already handles spacing around guards.
///
/// Lint: If a multi-line control flow statement is not preceded by a blank line, a lint warning is
/// raised.
///
/// Rewrite: A blank line is inserted before the control flow statement.
final class InsertBlankLineBeforeControlFlowBlocks: StaticFormatRule<BasicRuleValue>,
    @unchecked Sendable
{
    static let rewriteOrder = 210

    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // Diagnose against the pre-traversal (still-attached) node so finding source locations are
    // accurate. The compact-pipeline rewrite (called from `Rewrites/Stmts/CodeBlock.swift` and
    // `SwitchCase.swift` ) handles the rewrite without diagnose.
    static func willEnter(_ node: CodeBlockSyntax, context: Context) {
        _ = insertBlankLines(
            in: Array(node.statements),
            indentColumn: syntacticIndentColumn(of: Syntax(node), context: context),
            context: context,
            diagnose: true
        )
    }

    static func willEnter(_ node: SwitchCaseSyntax, context: Context) {
        _ = insertBlankLines(
            in: Array(node.statements),
            indentColumn: syntacticIndentColumn(of: Syntax(node), context: context),
            context: context,
            diagnose: true
        )
    }

    static func transform(
        _ node: CodeBlockSyntax,
        original: CodeBlockSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockSyntax {
        guard let updated = insertBlankLines(
            in: Array(node.statements),
            indentColumn: syntacticIndentColumn(of: Syntax(original), context: context),
            context: context
        ) else { return node }

        var result = node
        result.statements = CodeBlockItemListSyntax(updated)
        return result
    }

    static func transform(
        _ node: SwitchCaseSyntax,
        original: SwitchCaseSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SwitchCaseSyntax {
        guard let updated = insertBlankLines(
            in: Array(node.statements),
            indentColumn: syntacticIndentColumn(of: Syntax(original), context: context),
            context: context
        ) else { return node }

        var result = node
        result.statements = CodeBlockItemListSyntax(updated)
        return result
    }

    /// Insert a leading blank line before every multi-line control-flow statement that doesn't
    /// already have one, respecting the `closingBraceAsBlankLine` and `countCommentAsBlankLine`
    /// configuration flags.
    ///
    /// - Parameters:
    ///   - items: the statements of one block
    ///   - indentColumn: the column the layout indents those statements to
    private static func insertBlankLines(
        in items: [CodeBlockItemSyntax],
        indentColumn: Int,
        context: Context,
        diagnose: Bool = false
    ) -> [CodeBlockItemSyntax]? {
        guard items.count > 1 else { return nil }

        var statements = items
        var modified = false

        let braceIsBlank = context.configuration[TreatClosingBraceAsBlankLine.self]
        let commentIsBlank = context.configuration[TreatCommentAsBlankLine.self]

        for i in 1..<items.count {
            let item = items[i]
            guard isMultiLineControlFlow(item, indentColumn: indentColumn, context: context) else {
                continue
            }
            guard !item.leadingTrivia.hasBlankLine else { continue }
            if braceIsBlank, endsSolitaryBrace(items[i - 1]) { continue }
            if commentIsBlank, item.leadingTrivia.startsWithComment { continue }

            if diagnose {
                Self.diagnose(
                    .insertBlankLineBeforeControlFlow,
                    on: items[i].item,
                    context: context
                )
            }
            var next = item
            next.leadingTrivia = .newline + item.leadingTrivia
            statements[i] = next
            modified = true
        }

        return modified ? statements : nil
    }

    private static func endsSolitaryBrace(_ item: CodeBlockItemSyntax) -> Bool {
        guard let lastToken = item.lastToken(viewMode: .sourceAccurate),
              lastToken.tokenKind == .rightBrace else { return false }
        return lastToken.leadingTrivia.containsNewlines
    }

    /// Whether a statement is control flow that occupies more than one line once the layout runs
    ///
    /// - Parameters:
    ///   - item: the statement to classify
    ///   - indentColumn: the column the layout indents the statement to
    private static func isMultiLineControlFlow(
        _ item: CodeBlockItemSyntax,
        indentColumn: Int,
        context: Context
    ) -> Bool {
        let expands = willExpand(item, indentColumn: indentColumn, context: context)

        switch item.item {
            case let .stmt(stmt):
                if let forStmt = stmt.as(ForStmtSyntax.self) {
                    return isMultiLineBody(forStmt.body, expands: expands)
                }
                if let whileStmt = stmt.as(WhileStmtSyntax.self) {
                    return isMultiLineBody(whileStmt.body, expands: expands)
                }
                if let repeatStmt = stmt.as(RepeatStmtSyntax.self) {
                    return isMultiLineBody(repeatStmt.body, expands: expands)
                }
                if let doStmt = stmt.as(DoStmtSyntax.self) {
                    return isMultiLineBody(doStmt.body, expands: expands)
                }
                if let deferStmt = stmt.as(DeferStmtSyntax.self) {
                    return isMultiLineBody(deferStmt.body, expands: expands)
                }

                if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
                    return isMultiLineControlFlowExpr(exprStmt.expression, expands: expands)
                }
                return false
            case let .expr(expr): return isMultiLineControlFlowExpr(expr, expands: expands)
            default: return false
        }
    }

    /// Whether the layout breaks the statement across lines that the source wrote on one
    ///
    /// The rule runs before the pretty printer, so a body written inline still reads as one line
    /// here even when it overflows and the printer is about to expand it. Comparing the joined
    /// width against the line length catches that expansion. Without the comparison the blank line
    /// only goes in on a second format call.
    private static func willExpand(
        _ item: CodeBlockItemSyntax,
        indentColumn: Int,
        context: Context
    ) -> Bool { indentColumn + joinedWidth(of: item) > context.configuration[LineLength.self] }

    private static func isMultiLineControlFlowExpr(_ expr: ExprSyntax, expands: Bool) -> Bool {
        if let ifExpr = expr.as(IfExprSyntax.self) {
            isMultiLineBody(ifExpr.body, expands: expands)
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            switchExpr.rightBrace.leadingTrivia.containsNewlines
        } else {
            false
        }
    }

    private static func isMultiLineBody(_ body: CodeBlockSyntax, expands: Bool) -> Bool {
        body.rightBrace.leadingTrivia.containsNewlines || expands
    }
}

fileprivate extension Finding.Message {
    static let insertBlankLineBeforeControlFlow: Finding.Message =
        "insert blank line before control flow statement"
}
