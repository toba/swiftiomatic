import SwiftSyntax

/// Compact-pipeline merge of all `CodeBlockSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// No node-local rules currently target `CodeBlockSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteCodeBlock(
    _ node: CodeBlockSyntax,
    parent: Syntax?,
    context: Context
) -> CodeBlockSyntax {
    var result = node
    // BlankLinesAfterGuardStatements — collapses blank lines between
    // consecutive guard statements and inserts a blank line after the last
    // guard. Inlined from
    // `Sources/SwiftiomaticKit/Rules/BlankLines/BlankLinesAfterGuardStatements.swift`.
    if context.shouldRewrite(BlankLinesAfterGuardStatements.self, at: Syntax(result)) {
        result = applyBlankLinesAfterGuardStatements(result, context: context)
    }

    // BlankLinesBeforeControlFlowBlocks — inserts a blank line before
    // multi-line control-flow statements.
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(result)) {
        if let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
            in: Array(result.statements),
            context: context
        ) {
            result.statements = CodeBlockItemListSyntax(updated)
        }
    }

    return result
}

private func applyBlankLinesAfterGuardStatements(
    _ node: CodeBlockSyntax,
    context: Context
) -> CodeBlockSyntax {
    let originalStatements = Array(node.statements)
    var statements = originalStatements
    var modified = false

    for i in 0..<originalStatements.count {
        guard originalStatements[i].item.is(GuardStmtSyntax.self) else { continue }

        let nextIndex = i + 1
        guard nextIndex < originalStatements.count else { continue }

        let nextStmt = originalStatements[nextIndex]
        let nextIsConsecutiveGuard =
            nextStmt.item.is(GuardStmtSyntax.self) && !nextStmt.leadingTrivia.hasAnyComments

        if nextIsConsecutiveGuard {
            guard nextStmt.leadingTrivia.hasBlankLine else { continue }
            BlankLinesAfterGuardStatements.diagnose(
                .removeBlankLineBetweenGuards,
                on: nextStmt.item,
                context: context
            )
            var modifiedNext = nextStmt
            modifiedNext.leadingTrivia = nextStmt.leadingTrivia.replacingFirstNewlines(with: 1)
            statements[nextIndex] = modifiedNext
            modified = true
        } else {
            guard !nextStmt.leadingTrivia.hasBlankLine else { continue }
            BlankLinesAfterGuardStatements.diagnose(
                .insertBlankLineAfterGuard,
                on: originalStatements[i].item,
                context: context
            )
            var modifiedNext = nextStmt
            modifiedNext.leadingTrivia = .newline + nextStmt.leadingTrivia
            statements[nextIndex] = modifiedNext
            modified = true
        }
    }

    guard modified else { return node }
    var result = node
    result.statements = CodeBlockItemListSyntax(statements)
    return result
}

extension Finding.Message {
    fileprivate static let removeBlankLineBetweenGuards: Finding.Message =
        "remove blank line between consecutive guard statements"

    fileprivate static let insertBlankLineAfterGuard: Finding.Message =
        "insert blank line after guard statement"
}
