import SwiftSyntax

/// Insert a blank line after multiline switch case bodies.
///
/// When a switch case body spans multiple statements, a blank line after it improves readability by
/// visually separating it from the next case. Single-statement cases do not require blank lines.
/// The last case in a switch is never followed by a blank line (the closing brace provides visual
/// separation).
///
/// Lint: If a multiline case body is not followed by a blank line, a lint warning is raised. If the
/// last case is followed by a blank line before `}` , a lint warning is raised.
///
/// Rewrite: Blank lines are inserted after multiline cases and removed after the last case.
final class InsertBlankLineAfterSwitchCase: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Insert blank lines after multiline cases and strip a blank line before the closing brace.
    /// Called from `CompactSyntaxRewriter.visit(_: SwitchExprSyntax)` .
    static func apply(_ node: SwitchExprSyntax, context: Context) -> SwitchExprSyntax {
        var switchExpr = node
        let cases = Array(switchExpr.cases)
        guard !cases.isEmpty else { return node }

        var modifiedCases = cases
        var modified = false

        for i in 0..<(cases.count - 1) {
            guard case let .switchCase(switchCase) = cases[i],
                  switchCase.statements.count > 1 else { continue }

            let nextIndex = i + 1
            guard !cases[nextIndex].leadingTrivia.hasBlankLine else { continue }

            Self.diagnose(
                .insertBlankLineAfterCase,
                on: switchCase.label,
                context: context
            )
            modifiedCases[nextIndex] = modifiedCases[nextIndex].prependingNewline()
            modified = true
        }

        if modified { switchExpr.cases = SwitchCaseListSyntax(modifiedCases) }

        if switchExpr.rightBrace.leadingTrivia.hasBlankLine {
            Self.diagnose(
                .removeBlankLineBeforeClosingBrace,
                on: switchExpr.rightBrace,
                context: context
            )
            switchExpr.rightBrace = switchExpr.rightBrace.with(
                \.leadingTrivia,
                switchExpr.rightBrace.leadingTrivia.reducingToSingleNewlines
            )
            modified = true
        }

        return modified ? switchExpr : node
    }
}

fileprivate extension Finding.Message {
    static let insertBlankLineAfterCase: Finding.Message =
        "insert blank line after multiline switch case"

    static let removeBlankLineBeforeClosingBrace: Finding.Message =
        "remove blank line before closing brace"
}
