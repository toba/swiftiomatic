/// Unified read-only facade that queries both Lint and Format rule registries.
enum RuleCatalog {
    struct Entry: Codable, Sendable {
        let id: String
        let name: String
        let subsystem: Subsystem
        let kind: String
        let isEnabled: Bool
        let isDeprecated: Bool
    }

    enum Subsystem: String, Codable, Sendable {
        case suggest
        case lint
        case format
    }

    /// All rules across all subsystems, sorted by subsystem then id.
    static func allRules() -> [Entry] {
        var entries: [Entry] = []

        // Suggest categories (deep analysis via Analyzer + TypeResolver)
        for category in Category.allCases {
            entries.append(
                Entry(
                    id: category.rawValue,
                    name: category.displayName,
                    subsystem: .suggest,
                    kind: "suggest",
                    isEnabled: true,
                    isDeprecated: false
                )
            )
        }

        // Lint rules (AST-based, via SwiftLint engine)
        RuleRegistry.registerAllRulesOnce()
        let ruleList = RuleRegistry.shared.list
        for (identifier, ruleType) in ruleList.list {
            let desc = ruleType.description
            let isOptIn = ruleType is any OptInRule.Type
            entries.append(
                Entry(
                    id: identifier,
                    name: desc.name,
                    subsystem: .lint,
                    kind: desc.kind.rawValue,
                    isEnabled: !isOptIn,
                    isDeprecated: !desc.deprecatedAliases.isEmpty
                        && desc.deprecatedAliases.contains(identifier)
                )
            )
        }

        // Format rules (token-based, via SwiftFormat engine)
        let defaultRuleNames = Set(FormatRules.default.map(\.name))
        for rule in FormatRules.all {
            entries.append(
                Entry(
                    id: rule.name,
                    name: rule.name,
                    subsystem: .format,
                    kind: "format",
                    isEnabled: defaultRuleNames.contains(rule.name),
                    isDeprecated: rule.isDeprecated
                )
            )
        }

        return entries.sorted { ($0.subsystem.rawValue, $0.id) < ($1.subsystem.rawValue, $1.id) }
    }
}
