/// Value type for lint-only syntax rules that cannot rewrite source code.
///
/// Unlike ``LintValue``, this type only encodes the `lint` severity.
/// The `rewrite` property always returns `false` and its setter is a no-op.
///
/// ## JSON encoding
///
/// Always an object with only `lint`:
/// ```json
/// "someRule": { "lint": "warn" }
/// ```
///
/// Decoding accepts an optional `rewrite` key for backward compatibility
/// but silently ignores it.
package struct LintOnlyValue: SyntaxRuleValue {
    package var lint: Lint

    /// Always `false` for lint-only rules.
    package var rewrite: Bool {
        get { false }
        set { /* lint-only rules cannot rewrite */ }
    }

    package init() {
        self.lint = .warn
    }

    package init(lint: Lint) {
        self.lint = lint
    }
}

extension LintOnlyValue: Codable {
    package init(from decoder: any Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        // Accept and ignore `rewrite` for backward compatibility.
        _ = try keyed.decodeIfPresent(Bool.self, forKey: .rewrite)
        self.lint = try keyed.decodeIfPresent(Lint.self, forKey: .lint) ?? .warn
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lint, forKey: .lint)
    }

    private enum CodingKeys: String, CodingKey {
        case rewrite
        case lint
    }
}
