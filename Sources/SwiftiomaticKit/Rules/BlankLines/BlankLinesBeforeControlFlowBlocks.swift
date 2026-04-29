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
final class BlankLinesBeforeControlFlowBlocks: RewriteSyntaxRule<BasicRuleValue>,
    @unchecked Sendable
{
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // Diagnose against the pre-traversal (still-attached) node so finding
    // source locations are accurate. The compact-pipeline rewrite (in
    // `Rewrites/Stmts/BlankLinesBeforeControlFlowHelpers.swift`) handles
    // the rewrite without diagnose.
    static func willEnter(_ node: CodeBlockSyntax, context: Context) {
        _ = blankLinesBeforeControlFlowInsertBlankLines(
            in: Array(node.statements),
            context: context,
            diagnose: true
        )
    }

    static func willEnter(_ node: SwitchCaseSyntax, context: Context) {
        _ = blankLinesBeforeControlFlowInsertBlankLines(
            in: Array(node.statements),
            context: context,
            diagnose: true
        )
    }

}

fileprivate extension Finding.Message {
    static let insertBlankLineBeforeControlFlow: Finding.Message =
        "insert blank line before control flow statement"
}
