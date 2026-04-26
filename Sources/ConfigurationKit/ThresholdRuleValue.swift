/// Value type for lint-only syntax rules whose severity is decided by
/// dual numeric thresholds rather than a single `lint` setting.
///
/// These rules emit a warning-severity finding when a measured value crosses
/// `warning`, and an error-severity finding when it crosses `error`. The
/// severity is encoded in the thresholds themselves, so the rule exposes a
/// simple `enabled: Bool` toggle instead of a `lint: Lint` field.
///
/// ## JSON encoding
///
/// ```json
/// "someRule": { "enabled": true, "warning": 30, "error": 50 }
/// ```
///
/// Conformance to ``SyntaxRuleValue`` is satisfied by synthesized
/// `lint`/`rewrite` bridges — `lint` mirrors `enabled` (active when enabled),
/// `rewrite` is always `false`. Pipeline code that reads `.isActive` keeps
/// working unchanged.
package protocol ThresholdRuleValue: SyntaxRuleValue {
    /// Whether the rule should run. `false` silences all findings.
    var enabled: Bool { get set }
    /// Values at or above this threshold emit a warning-severity finding.
    var warning: Int { get set }
    /// Values at or above this threshold emit an error-severity finding.
    var error: Int { get set }
}

extension ThresholdRuleValue {
    package var rewrite: Bool {
        get { false }
        set { }
    }
    package var lint: Lint {
        get { enabled ? .warn : .no }
        set { enabled = newValue.isActive }
    }
}
