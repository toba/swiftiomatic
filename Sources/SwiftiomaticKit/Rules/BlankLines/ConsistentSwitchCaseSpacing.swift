import SwiftSyntax

/// Ensure consistent blank-line spacing among all cases in a switch statement.
///
/// When some cases in a switch are separated by blank lines and others aren't, the
/// inconsistency looks sloppy. This rule normalizes to whichever style is used by
/// the majority of cases: if more cases have blank lines, missing ones are added;
/// if fewer do, extra ones are removed. The last case is excluded (it's always
/// followed by `}`).
///
/// Lint: If any case's spacing is inconsistent with the majority, a lint warning is raised.
///
/// Format: Blank lines are added or removed to make spacing consistent.
final class ConsistentSwitchCaseSpacing: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    //    override class var key: String { "betweenScopes" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard var switchExpr = visited.as(SwitchExprSyntax.self) else { return visited }

        let cases = Array(switchExpr.cases)
        // Need at least 2 cases (last case is excluded from spacing decisions).
        guard cases.count >= 2 else { return visited }

        // Count cases with/without blank lines (exclude last case).
        var withBlank = 0
        var withoutBlank = 0

        for i in 0..<(cases.count - 1) {
            if cases[i + 1].leadingTrivia.hasBlankLine {
                withBlank += 1
            } else {
                withoutBlank += 1
            }
        }

        // Majority wins; ties favor blank lines.
        let shouldHaveBlankLines = withBlank >= withoutBlank

        var modifiedCases = cases
        var modified = false

        for i in 0..<(cases.count - 1) {
            let nextIndex = i + 1
            let currentlyHasBlank = cases[nextIndex].leadingTrivia.hasBlankLine

            if shouldHaveBlankLines, !currentlyHasBlank {
                diagnose(.addBlankLineForConsistency, on: cases[nextIndex])
                modifiedCases[nextIndex] = modifiedCases[nextIndex].prependingNewline()
                modified = true
            } else if !shouldHaveBlankLines, currentlyHasBlank {
                diagnose(.removeBlankLineForConsistency, on: cases[nextIndex])
                modifiedCases[nextIndex] = modifiedCases[nextIndex].removingBlankLines()
                modified = true
            }
        }

        guard modified else { return visited }
        switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
        return ExprSyntax(switchExpr)
    }
}

extension Finding.Message {
    fileprivate static let addBlankLineForConsistency: Finding.Message =
        "add blank line between switch cases for consistency"

    fileprivate static let removeBlankLineForConsistency: Finding.Message =
        "remove blank line between switch cases for consistency"
}
