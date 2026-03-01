/// Unified read-only facade that queries Suggest, Lint, and Format rule registries
public enum RuleCatalog {
    /// All rules across all engines as ``RuleConfigurationEntry`` values, sorted by scope then id
    public static func allEntries() -> [RuleConfigurationEntry] {
        var entries: [RuleConfigurationEntry] = []

        // Lint rules (AST-based, run through unified Analyzer)
        RuleRegistry.registerAllRulesOnce()
        let ruleList = RuleRegistry.shared.list
        for (_, ruleType) in ruleList.rules {
            let adapter = LintRuleConfigurationAdapter(ruleType)
            entries.append(adapter.toEntry())
        }

        // Format rules (token-based, via SwiftFormat engine)
        let defaultRuleNames = Set(FormatRules.default.map(\.name))
        for rule in FormatRules.all {
            let adapter = FormatRuleConfigurationAdapter(
                rule, isDefault: defaultRuleNames.contains(rule.name),
            )
            entries.append(adapter.toEntry())
        }

        return entries.sorted { ($0.scope.rawValue, $0.id) < ($1.scope.rawValue, $1.id) }
    }

    /// Look up a single rule by ID across all engines
    ///
    /// - Parameters:
    ///   - id: The unique rule identifier to search for.
    /// - Returns: The matching ``RuleConfigurationEntry``, or `nil` if no rule matches.
    public static func entry(id: String) -> RuleConfigurationEntry? {
        allEntries().first { $0.id == id }
    }

    /// All rules for a specific ``Scope``
    ///
    /// - Parameters:
    ///   - scope: The scope to filter by.
    /// - Returns: All entries whose scope matches.
    public static func entries(for scope: Scope) -> [RuleConfigurationEntry] {
        allEntries().filter { $0.scope == scope }
    }
}

extension RuleConfiguration {
    /// Convert any ``RuleConfiguration`` to a concrete ``RuleConfigurationEntry``
    func toEntry() -> RuleConfigurationEntry {
        RuleConfigurationEntry(
            id: id,
            name: name,
            summary: summary,
            rationale: rationale,
            scope: scope,
            isCorrectable: isCorrectable,
            isOptIn: isOptIn,
            isDeprecated: isDeprecated,
            deprecationMessage: deprecationMessage,
            requiresSourceKit: requiresSourceKit,
            requiresCompilerArguments: requiresCompilerArguments,
            isCrossFile: isCrossFile,
            canEnrichAsync: canEnrichAsync,
            examples: examples,
            configurationOptions: configurationOptions,
            relatedRuleIDs: relatedRuleIDs,
        )
    }
}
