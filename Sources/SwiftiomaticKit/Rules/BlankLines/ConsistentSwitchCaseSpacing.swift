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
/// Rewrite: Blank lines are added or removed to make spacing consistent.
final class ConsistentSwitchCaseSpacing: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Normalize blank-line spacing among switch cases to whichever style is
    /// used by the majority. Called from
    /// `CompactStageOneRewriter.visit(_: SwitchExprSyntax)`.
    static func apply(_ node: SwitchExprSyntax, context: Context) -> SwitchExprSyntax {
        var switchExpr = node
        let cases = Array(switchExpr.cases)
        // Need at least 2 cases (last case is excluded from spacing decisions).
        guard cases.count >= 2 else { return node }

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
                Self.diagnose(
                    .switchSpacingAddBlankLine,
                    on: cases[nextIndex],
                    context: context
                )
                modifiedCases[nextIndex] = modifiedCases[nextIndex].prependingNewline()
                modified = true
            } else if !shouldHaveBlankLines, currentlyHasBlank {
                Self.diagnose(
                    .switchSpacingRemoveBlankLine,
                    on: cases[nextIndex],
                    context: context
                )
                modifiedCases[nextIndex] = modifiedCases[nextIndex].removingBlankLines()
                modified = true
            }
        }

        guard modified else { return node }
        switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
        return switchExpr
    }
}

extension Finding.Message {
    fileprivate static let switchSpacingAddBlankLine: Finding.Message =
        "add blank line between switch cases for consistency"

    fileprivate static let switchSpacingRemoveBlankLine: Finding.Message =
        "remove blank line between switch cases for consistency"
}
