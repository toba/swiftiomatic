import SwiftSyntax

/// Insert a blank line before control flow statements with multi-line bodies.
///
/// When a `for` , `while` , `repeat` , `if` , `switch` , `do` , or `defer` statement has a
/// multi-line body and is preceded by another statement, a blank line before it improves
/// readability. Single-line (inline) control flow is excluded. Guard statements are excluded
/// because `BlankLinesAfterGuardStatements` already handles spacing around guards.
///
/// Lint: If a multi-line control flow statement is not preceded by a blank line, a lint warning is
/// raised.
///
/// Rewrite: A blank line is inserted before the control flow statement.
final class BlankLinesBeforeControlFlowBlocks: StaticFormatRule<BasicRuleValue>,
    @unchecked Sendable
{
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // Diagnose against the pre-traversal (still-attached) node so finding
    // source locations are accurate. The compact-pipeline rewrite (called
    // from `Rewrites/Stmts/CodeBlock.swift` and `SwitchCase.swift`) handles
    // the rewrite without diagnose.
    static func willEnter(_ node: CodeBlockSyntax, context: Context) {
        _ = insertBlankLines(in: Array(node.statements), context: context, diagnose: true)
    }

    static func willEnter(_ node: SwitchCaseSyntax, context: Context) {
        _ = insertBlankLines(in: Array(node.statements), context: context, diagnose: true)
    }

    /// Insert a leading blank line before every multi-line control-flow statement
    /// that doesn't already have one, respecting the `closingBraceAsBlankLine`
    /// and `commentAsBlankLine` configuration flags.
    static func insertBlankLines(
        in items: [CodeBlockItemSyntax],
        context: Context,
        diagnose: Bool = false
    ) -> [CodeBlockItemSyntax]? {
        guard items.count > 1 else { return nil }

        var statements = items
        var modified = false

        let braceIsBlank = context.configuration[ClosingBraceAsBlankLine.self]
        let commentIsBlank = context.configuration[CommentAsBlankLine.self]

        for i in 1..<items.count {
            let item = items[i]
            guard isMultiLineControlFlow(item.item) else { continue }
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
              lastToken.tokenKind == .rightBrace
        else { return false }
        return lastToken.leadingTrivia.containsNewlines
    }

    private static func isMultiLineControlFlow(_ item: CodeBlockItemSyntax.Item) -> Bool {
        switch item {
            case let .stmt(stmt):
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
                if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
                    return isMultiLineControlFlowExpr(exprStmt.expression)
                }
                return false
            case let .expr(expr): return isMultiLineControlFlowExpr(expr)
            default: return false
        }
    }

    private static func isMultiLineControlFlowExpr(_ expr: ExprSyntax) -> Bool {
        if let ifExpr = expr.as(IfExprSyntax.self) {
            isMultiLineBody(ifExpr.body)
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            switchExpr.rightBrace.leadingTrivia.containsNewlines
        } else {
            false
        }
    }

    private static func isMultiLineBody(_ body: CodeBlockSyntax) -> Bool {
        body.rightBrace.leadingTrivia.containsNewlines
    }
}

fileprivate extension Finding.Message {
    static let insertBlankLineBeforeControlFlow: Finding.Message =
        "insert blank line before control flow statement"
}
