import Foundation

/// Unified read-only facade that queries Suggest, Lint, and Format rule registries
public enum RuleCatalog {
    /// All rules across all engines as ``RuleConfigurationEntry`` values, sorted by scope then id
    public static func allEntries() -> [RuleConfigurationEntry] {
        var entries: [RuleConfigurationEntry] = []

        // Lint rules (AST-based, run through unified Analyzer)
        RuleRegistry.registerAllRulesOnce()
        let ruleList = RuleRegistry.shared.list
        for (_, ruleType) in ruleList.rules {
            entries.append(makeEntry(from: ruleType))
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

// MARK: - Rule type → RuleConfigurationEntry conversion

// MARK: - RuleOptionsDescription → ConfigOptionDescriptor

extension RuleOptionsDescription {
    /// Convert this options description into uniform ``ConfigOptionDescriptor`` values
    func toConfigOptionDescriptors() -> [ConfigOptionDescriptor] {
        let yamlString = yaml()
        guard !yamlString.isEmpty else { return [] }

        return yamlString.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let valueType = inferValueType(from: value)
            return ConfigOptionDescriptor(
                key: key,
                displayName: key.replacingOccurrences(of: "_", with: " ").capitalized,
                help: "",
                valueType: valueType,
                defaultValue: value,
            )
        }
    }

    private func inferValueType(from value: String) -> ConfigValueType {
        if value == "true" || value == "false" {
            return .bool
        }
        if value == "warning" || value == "error" {
            return .severity
        }
        if Int(value) != nil {
            return .int
        }
        if Double(value) != nil {
            return .float
        }
        if value.hasPrefix("[") {
            return .list
        }
        return .string
    }
}

/// Build a ``RuleConfigurationEntry`` from a lint rule type's static metadata
private func makeEntry(from ruleType: any Rule.Type) -> RuleConfigurationEntry {
    let rule = ruleType.init()
    let desc = rule.createConfigurationDescription()
    let configOptions = desc.hasContent ? desc.toConfigOptionDescriptors() : []

    let isDeprecatedRule: Bool = {
        let aliases = ruleType.ruleDeprecatedAliases
        return !aliases.isEmpty && aliases.contains(ruleType.identifier)
    }()

    return RuleConfigurationEntry(
        id: ruleType.identifier,
        name: ruleType.ruleName,
        summary: ruleType.ruleSummary,
        rationale: ruleType.ruleRationale,
        scope: ruleType.ruleScope,
        isCorrectable: ruleType is any CorrectableRule.Type,
        isOptIn: ruleType.isOptIn,
        isDeprecated: isDeprecatedRule,
        deprecationMessage: ruleType.deprecationMessage,
        requiresSourceKit: ruleType.runsWithSourceKit,
        requiresCompilerArguments: ruleType.runsWithCompilerArguments,
        isCrossFile: ruleType is any CollectingRuleMarker.Type,
        canEnrichAsync: ruleType is any AsyncEnrichableRule.Type,
        examples: ruleType.examples,
        configurationOptions: configOptions,
        relatedRuleIDs: ruleType.relatedRuleIDs,
    )
}
