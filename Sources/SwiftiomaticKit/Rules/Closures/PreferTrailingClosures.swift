import SwiftSyntax

/// Use trailing closure syntax where applicable.
///
/// When the last argument(s) to a function call are closure expressions, convert them to trailing
/// closure syntax. For a single trailing closure, the closure must be unlabeled unless the function
/// is in the "always trailing" list (e.g. `async` , `sync` , `autoreleasepool` ). For multiple
/// trailing closures, the first must be unlabeled and the rest must be labeled.
///
/// Lint: When closure arguments could use trailing closure syntax.
///
/// Rewrite: The closure arguments are moved to trailing closure position.
final class PreferTrailingClosures: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .closures }
}
