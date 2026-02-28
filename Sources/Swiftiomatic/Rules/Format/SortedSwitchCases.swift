import Foundation

extension FormatRule {
    /// Deprecated
    static let sortedSwitchCases = FormatRule(
        help: "Sort switch cases alphabetically.",
        deprecationMessage: "Use sortSwitchCases instead.",
    ) { formatter in
        FormatRule.sortSwitchCases.apply(with: formatter)
    } examples: {
        nil
    }
}
