/// Public API surface for consumers outside the Swift package (e.g. Xcode Source Editor Extension).
/// Internal types remain `package` — this file exposes only what external targets need.
public enum SwiftiomaticLib {
    /// Format Swift source code using the default rules and options.
    public static func format(_ source: String) throws -> String {
        try FormatEngine().format(source)
    }

    /// Format Swift source code using the given configuration.
    public static func format(_ source: String, configuration: Configuration) throws -> String {
        try configuration.makeFormatEngine().format(source)
    }

    /// Run lint-scope rules on a single source string and return diagnostics sorted by location.
    public static func lint(_ source: String, fileName: String = "<stdin>") -> [Diagnostic] {
        RuleRegistry.registerAllRulesOnce()
        let file = SwiftSource(contents: source)

        let rules = RuleResolver.loadRules(skipAnalyzerRules: true)
        let lintRules = rules.filter { type(of: $0).description.scope == .lint }

        var diagnostics: [Diagnostic] = []
        for rule in lintRules {
            let violations = rule.validate(file: file)
            for violation in violations {
                diagnostics.append(violation.toDiagnostic())
            }
        }
        return diagnostics.sorted()
    }

    /// Returns metadata for every registered rule, sorted by identifier.
    public static func ruleCatalog() -> [RuleCatalogEntry] {
        RuleRegistry.registerAllRulesOnce()
        let ruleList = RuleRegistry.shared.list

        var entries: [RuleCatalogEntry] = []

        // Lint rules (AST-based)
        for (identifier, ruleType) in ruleList.rules {
            let desc = ruleType.description
            entries.append(
                RuleCatalogEntry(
                    identifier: identifier,
                    name: desc.name,
                    description: desc.description,
                    rationale: desc.rationale,
                    scope: desc.scope,
                    isCorrectable: ruleType is any CorrectableRule.Type,
                    isOptIn: ruleType is any OptInRule.Type,
                ),
            )
        }

        // Format rules (token-based)
        for rule in FormatRules.all {
            let isDefault = FormatRules.default.contains(where: { $0.name == rule.name })
            entries.append(
                RuleCatalogEntry(
                    identifier: rule.name,
                    name: rule.name,
                    description: stripMarkdown(rule.help),
                    rationale: nil,
                    scope: .format,
                    isCorrectable: true,
                    isOptIn: !isDefault,
                ),
            )
        }

        return entries.sorted { $0.identifier < $1.identifier }
    }

    /// Load a configuration from a YAML file at the given path.
    public static func loadConfiguration(from path: String) throws -> Configuration {
        try Configuration.loadUnified(from: path)
    }

    /// Save a configuration to a YAML file at the given path.
    public static func saveConfiguration(_ config: Configuration, to path: String) throws {
        try config.writeYAML(to: path)
    }
}
