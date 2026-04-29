import SwiftSyntax

/// Insert blank lines before and after `// MARK:` comments.
///
/// MARK comments serve as section dividers. Surrounding them with blank lines makes the
/// visual separation clear. A blank line before MARK is skipped when the MARK immediately
/// follows an opening brace (start of scope). A blank line after MARK is skipped when
/// the MARK immediately precedes a closing brace (end of scope) or end of file.
///
/// Lint: If a MARK comment is missing a blank line before or after it, a lint warning is raised.
///
/// Rewrite: Blank lines are inserted around MARK comments.
/// The compact pipeline calls `applyBlankLinesAroundMark` directly from
/// `Rewrites/Tokens/TokenRewrites.swift`. This class only exists so the rule
/// is registered (configuration key, group, default value). It has no visit /
/// transform / willEnter / didExit methods — `RuleCollector` allows that.
final class BlankLinesAroundMark: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "aroundMark" }
    override static var group: ConfigurationGroup? { .blankLines }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
}
