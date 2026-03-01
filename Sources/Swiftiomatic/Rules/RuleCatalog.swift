/// Unified read-only facade that queries Suggest, Lint, and Format rule registries
public enum RuleCatalog {
    /// A single rule entry aggregated from any engine (lint, format, or suggest)
    public struct Entry: Codable, Sendable {
        public let id: String
        public let name: String
        public let source: DiagnosticSource
        public let description: String
        public let isEnabled: Bool
        public let isDeprecated: Bool
        public let canAutoFix: Bool
        public let isCrossFile: Bool
        public let requiresSourceKit: Bool
    }

    /// All rules across all engines, sorted by source then id
    public static func allRules() -> [Entry] {
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

    /// Look up a single rule by ID across all engines
    ///
    /// - Parameters:
    ///   - id: The unique rule identifier to search for.
    /// - Returns: The matching ``Entry``, or `nil` if no rule matches.
    static func rule(id: String) -> Entry? {
        allRules().first { $0.id == id }
    }

    /// All rules for a specific ``DiagnosticSource``
    ///
    /// - Parameters:
    ///   - source: The diagnostic source to filter by.
    /// - Returns: All entries whose source matches.
    public static func rules(for source: DiagnosticSource) -> [Entry] {
        allRules().filter { $0.source == source }
    }
}
