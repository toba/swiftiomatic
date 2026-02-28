import Foundation

extension FormatRule {
    static let throwingTests = FormatRule(
        help: "Write tests that use `throws` instead of using `try!`.",
        deprecationMessage: "Renamed to `noForceTryInTests`.",
        disabledByDefault: true,
    ) { formatter in
        FormatRule.noForceTryInTests.apply(with: formatter)
    } examples: {
        nil
    }
}
