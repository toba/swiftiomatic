/// Value type for syntax rules, adding rewrite and lint severity to the rule's configuration.
///
/// Every syntax rule's ``Configurable/Value`` must conform to this protocol. Layout rules do not
/// use this protocol — their values are plain types (Bool, Int, enum).
package protocol SyntaxRuleValue: Sendable, Codable, Equatable {
    /// Whether the rule rewrites (auto-fixes) source code.
    var rewrite: Bool { get set }
    /// Finding severity when the rule is active.
    var lint: Lint { get set }
    /// Default value with sensible defaults.
    init()
}

package extension SyntaxRuleValue {
    /// Whether the rule should run at all (rewrite or lint).
    var isActive: Bool { rewrite || lint.isActive }

    /// Whether the rule's rewrite path is active. Used by `Context.shouldRewrite` to gate auto-fix
    /// independently of lint-only emission, so a rule with `rewrite: false, lint: .warn` reports
    /// findings without modifying source.
    var isRewriteActive: Bool { rewrite }
}
