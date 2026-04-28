import SwiftSyntax

/// Shared helpers for the inlined `BlankLinesBeforeControlFlowBlocks` rule.
/// The rule applies the same insertion logic on `CodeBlockSyntax.statements`
/// and `SwitchCaseSyntax.statements`. See
/// `Sources/SwiftiomaticKit/Rules/BlankLines/BlankLinesBeforeControlFlowBlocks.swift`
/// for the legacy implementation.

/// Insert a leading blank line before every multi-line control-flow statement
/// that doesn't already have one, respecting the `closingBraceAsBlankLine`
/// and `commentAsBlankLine` configuration flags.
func blankLinesBeforeControlFlowInsertBlankLines(
    in items: [CodeBlockItemSyntax],
    context: Context
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

        BlankLinesBeforeControlFlowBlocks.diagnose(
            .insertBlankLineBeforeControlFlow,
            on: items[i].item,
            context: context
        )
        var next = item
        next.leadingTrivia = .newline + item.leadingTrivia
        statements[i] = next
        modified = true
    }

    return modified ? statements : nil
}

private func endsSolitaryBrace(_ item: CodeBlockItemSyntax) -> Bool {
    guard let lastToken = item.lastToken(viewMode: .sourceAccurate),
          lastToken.tokenKind == .rightBrace
    else { return false }
    return lastToken.leadingTrivia.containsNewlines
}

private func isMultiLineControlFlow(_ item: CodeBlockItemSyntax.Item) -> Bool {
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

private func isMultiLineControlFlowExpr(_ expr: ExprSyntax) -> Bool {
    if let ifExpr = expr.as(IfExprSyntax.self) {
        isMultiLineBody(ifExpr.body)
    } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
        switchExpr.rightBrace.leadingTrivia.containsNewlines
    } else {
        false
    }
}

private func isMultiLineBody(_ body: CodeBlockSyntax) -> Bool {
    body.rightBrace.leadingTrivia.containsNewlines
}

extension Finding.Message {
    fileprivate static let insertBlankLineBeforeControlFlow: Finding.Message =
        "insert blank line before control flow statement"
}
