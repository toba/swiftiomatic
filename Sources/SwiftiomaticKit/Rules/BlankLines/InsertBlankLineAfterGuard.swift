import SwiftSyntax

/// Remove blank lines between consecutive guard statements and insert a blank line after the last
/// guard.
///
/// Guard blocks at the top of a function form a precondition section. Keeping them tight (no blank
/// lines between them) and separated from the body (one blank line after) improves readability.
/// Comments between guards break the "consecutive" chain — each guard followed by a comment gets
/// its own trailing blank line.
///
/// Lint: If there are blank lines between consecutive guards, or no blank line after the last guard
/// before other code, a lint warning is raised.
///
/// Rewrite: Blank lines between consecutive guards are removed. A blank line is inserted after the
/// last guard when followed by non-guard code.
final class InsertBlankLineAfterGuard: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Inserts blank lines after guard statements and removes blank lines between consecutive
    /// guards in the code block. Returns `node` unchanged when nothing matched.
    static func apply(_ node: CodeBlockSyntax, context: Context) -> CodeBlockSyntax {
        let originalStatements = Array(node.statements)
        var statements = originalStatements
        var modified = false

        for i in 0..<originalStatements.count
        where originalStatements[i].item.is(GuardStmtSyntax.self) {
            let nextIndex = i + 1
            guard nextIndex < originalStatements.count else { continue }

            let nextStmt = originalStatements[nextIndex]
            let nextIsConsecutiveGuard = nextStmt.item.is(GuardStmtSyntax.self)
                && !nextStmt.leadingTrivia.hasAnyComments

            if nextIsConsecutiveGuard {
                guard nextStmt.leadingTrivia.hasBlankLine else { continue }
                Self.diagnose(
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
                Self.diagnose(
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
}

fileprivate extension Finding.Message {
    static let removeBlankLineBetweenGuards: Finding.Message =
        "remove blank line between consecutive guard statements"

    static let insertBlankLineAfterGuard: Finding.Message =
        "insert blank line after guard statement"
}
