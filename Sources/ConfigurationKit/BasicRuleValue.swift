/// Default value type for simple syntax rules that have no rule-specific configuration beyond
/// rewrite and lint severity.
///
/// ## JSON encoding
///
/// Always an object:
/// ```json
/// "someRule": { "rewrite": true, "lint": "warn" }
/// ```
package struct BasicRuleValue: SyntaxRuleValue {
    package var lint: Lint
    package var rewrite: Bool

    package init() {
        lint = .warn
        rewrite = true
    }

    package init(rewrite: Bool = true, lint: Lint = .warn) {
        self.lint = lint
        self.rewrite = rewrite
    }

    package init(_ lint: Lint) {
        self.lint = lint
        rewrite = true
    }
}

extension BasicRuleValue: Codable {
    package init(from decoder: any Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        let rewrite = try keyed.decodeIfPresent(Bool.self, forKey: .rewrite) ?? true
        let lint = try keyed.decodeIfPresent(Lint.self, forKey: .lint) ?? .warn
        self = BasicRuleValue(rewrite: rewrite, lint: lint)
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rewrite, forKey: .rewrite)
        try container.encode(lint, forKey: .lint)
    }

    private enum CodingKeys: String, CodingKey {
        case rewrite
        case lint
    }
}
