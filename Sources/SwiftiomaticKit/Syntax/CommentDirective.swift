/// Comment prefixes that carry an instruction to a tool
///
/// A line comment opening with one of these prefixes is not prose. Reflowing it, wrapping it or
/// converting it to a doc comment breaks the instruction it carries, so a rewrite leaves the whole
/// comment verbatim.
enum CommentDirective {
    /// Every recognized prefix, matched against a comment body.
    ///
    /// `sm:ignore` is the spelling `RuleMask` reads. No other spelling of it matches.
    static let prefixes = [
        "MARK:", "TODO:", "FIXME:", "WARNING:", "NOTE:", "HACK:",
        "sm:ignore", "swift-format-ignore",
        "swiftformat:", "swiftlint:", "sourcery:", "periphery:",
    ]

    /// True when `body` opens with a directive prefix
    ///
    /// - Parameter body: One comment line with its `//` prefix and its leading spaces removed
    static func matches(_ body: some StringProtocol) -> Bool {
        prefixes.contains { body.hasPrefix($0) }
    }
}
