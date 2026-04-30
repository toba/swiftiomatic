import ConfigurationKit
import SwiftSyntax

/// A rule that formats and/or lints, dispatched entirely through static
/// `transform`/`willEnter`/`didExit` hooks invoked by `CompactSyntaxRewriter`.
///
/// `StaticFormatRule` carries no per-file state — `Context` is threaded through
/// each static call. The base class exists only as a registration target so
/// `RuleCollector` can detect the rule via inheritance pattern, identical to the
/// way `LintSyntaxRule` and `StructuralFormatRule` are recognised.
///
/// Use this base class for the vast majority of compact-pipeline rules. Use
/// `StructuralFormatRule` only when the rule needs `SyntaxRewriter` machinery for
/// instance-level traversal (structural-pass rules, fresh-instance rewriters
/// like `PreferShorthandTypeNames`).
class StaticFormatRule<V: SyntaxRuleValue>: SyntaxRule, @unchecked Sendable {
    typealias Value = V

    // class var so subclass overrides dispatch correctly through the vtable
    // when accessed via protocol existentials (any SyntaxRule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last ?? "")
        return configurationKey(forTypeName: name)
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultValue: V { V() }
}
