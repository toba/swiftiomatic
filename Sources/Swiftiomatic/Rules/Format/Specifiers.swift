import Foundation

extension FormatRule {
    /// Deprecated
    static let specifiers = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        deprecationMessage: "Use modifierOrder instead.",
        options: ["modifier-order"],
    ) { formatter in
        _ = formatter.options.modifierOrder
        FormatRule.modifierOrder.apply(with: formatter)
    } examples: {
        nil
    }
}
