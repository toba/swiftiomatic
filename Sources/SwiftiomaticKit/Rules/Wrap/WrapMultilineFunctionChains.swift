import SwiftSyntax

/// Chained function calls are wrapped consistently: if any dot in the chain is on a different line,
/// all dots are placed on separate lines.
///
/// Lint: A multiline chain where some dots share a line raises a warning.
///
/// Rewrite: Dots that share a line with a closing scope or another dot are moved to their own line.
final class WrapMultilineFunctionChains: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var key: String { "multilineFunctionChains" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
