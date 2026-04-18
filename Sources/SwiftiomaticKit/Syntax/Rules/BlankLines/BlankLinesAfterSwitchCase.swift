import SwiftSyntax

/// Insert a blank line after multiline switch case bodies.
///
/// When a switch case body spans multiple statements, a blank line after it improves readability
/// by visually separating it from the next case. Single-statement cases do not require blank lines.
/// The last case in a switch is never followed by a blank line (the closing brace provides
/// visual separation).
///
/// Lint: If a multiline case body is not followed by a blank line, a lint warning is raised.
///       If the last case is followed by a blank line before `}`, a lint warning is raised.
///
/// Format: Blank lines are inserted after multiline cases and removed after the last case.
final class BlankLinesAfterSwitchCase: SyntaxFormatRule {
    static let group: ConfigGroup? = .blankLines

    static let defaultHandling: RuleHandling = .off

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard var switchExpr = visited.as(SwitchExprSyntax.self) else { return visited }

        let cases = Array(switchExpr.cases)
        guard !cases.isEmpty else { return visited }

        var modifiedCases = cases
        var modified = false

        // Insert blank lines after multiline non-last cases.
        for i in 0..<(cases.count - 1) {
            guard case .switchCase(let switchCase) = cases[i],
                switchCase.statements.count > 1
            else { continue }

            let nextIndex = i + 1
            guard !cases[nextIndex].leadingTrivia.hasBlankLine else { continue }

            diagnose(.insertBlankLineAfterCase, on: switchCase.label)
            modifiedCases[nextIndex] = modifiedCases[nextIndex].prependingNewline()
            modified = true
        }

        if modified {
            switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
        }

        // Remove blank line before closing brace after last case.
        if switchExpr.rightBrace.leadingTrivia.hasBlankLine {
            diagnose(.removeBlankLineBeforeClosingBrace, on: switchExpr.rightBrace)
            switchExpr.rightBrace = switchExpr.rightBrace.with(
                \.leadingTrivia,
                switchExpr.rightBrace.leadingTrivia.reducingToSingleNewlines
            )
            modified = true
        }

        return modified ? ExprSyntax(switchExpr) : visited
    }
}

extension Finding.Message {
    fileprivate static let insertBlankLineAfterCase: Finding.Message =
        "insert blank line after multiline switch case"

    fileprivate static let removeBlankLineBeforeClosingBrace: Finding.Message =
        "remove blank line before closing brace"
}
