/// Unified read-only facade that queries Suggest, Lint, and Format rule registries.
package enum RuleCatalog {
    package struct Entry: Codable, Sendable {
        package let id: String
        package let name: String
        package let source: DiagnosticSource
        package let description: String
        package let isEnabled: Bool
        package let isDeprecated: Bool
        package let canAutoFix: Bool
        package let isCrossFile: Bool
        package let requiresSourceKit: Bool
    }

    /// All rules across all engines, sorted by source then id.
    package static func allRules() -> [Entry] {
        var entries: [Entry] = []

        // Lint rules (AST-based, run through unified Analyzer)
        RuleRegistry.registerAllRulesOnce()
        let ruleList = RuleRegistry.shared.list
        for (identifier, ruleType) in ruleList.rules {
            let desc = ruleType.description
            let isOptIn = ruleType is any OptInRule.Type
            let isCorrectableType = ruleType is any CorrectableRule.Type
            let isAnalyzer = ruleType is any AnalyzerRule.Type
            entries.append(
                Entry(
                    id: identifier,
                    name: desc.name,
                    source: .lint,
                    description: desc.description,
                    isEnabled: !isOptIn,
                    isDeprecated: !desc.deprecatedAliases.isEmpty
                        && desc.deprecatedAliases.contains(identifier),
                    canAutoFix: isCorrectableType,
                    isCrossFile: false,
                    requiresSourceKit: isAnalyzer,
                ),
            )
        }

        // Format rules (token-based, via SwiftFormat engine)
        let defaultRuleNames = Set(FormatRules.default.map(\.name))
        for rule in FormatRules.all {
            entries.append(
                Entry(
                    id: rule.name,
                    name: rule.name,
                    source: .format,
                    description: stripMarkdown(rule.help),
                    isEnabled: defaultRuleNames.contains(rule.name),
                    isDeprecated: rule.isDeprecated,
                    canAutoFix: true,
                    isCrossFile: false,
                    requiresSourceKit: false,
                ),
            )
        }

        return entries.sorted { ($0.source.rawValue, $0.id) < ($1.source.rawValue, $1.id) }
    }

    /// Look up a single rule by ID across all engines.
    static func rule(id: String) -> Entry? {
        allRules().first { $0.id == id }
    }

    /// All rules for a specific source.
    package static func rules(for source: DiagnosticSource) -> [Entry] {
        allRules().filter { $0.source == source }
    }
}
