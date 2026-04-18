import SwiftSyntax

/// Remove `break` at the end of switch cases.
///
/// In Swift, switch cases do not fall through by default. A trailing `break` at the end of a
/// case body is therefore redundant.
///
/// This rule does NOT remove labeled `break` statements (e.g. `break outerLoop`), which transfer
/// control to a specific enclosing statement. It also does not remove `break` when it is the
/// sole statement in a case body (since at least one statement is required).
///
/// Lint: If a redundant `break` is found at the end of a switch case, a lint warning is raised.
///
/// Format: The redundant `break` statement is removed.
final class RedundantBreak: SyntaxFormatRule {
    static let group: ConfigGroup? = .redundancies

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        let visited = super.visit(node)
        let statements = visited.statements

        // A case must have at least one statement. If `break` is the only statement, it's required.
        guard statements.count > 1 else {
            return visited
        }

        // Check if the last statement is an unlabeled `break`.
        guard let lastItem = statements.last,
            let breakStmt = lastItem.item.as(StmtSyntax.self)?.as(BreakStmtSyntax.self),
            breakStmt.label == nil
        else {
            return visited
        }

        diagnose(.removeRedundantBreak, on: breakStmt.breakKeyword)

        // Remove the last statement (the redundant break).
        let newStatements = CodeBlockItemListSyntax(statements.dropLast())
        return visited.with(\.statements, newStatements)
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantBreak: Finding.Message =
        "remove redundant 'break'; switch cases do not fall through by default"
}
