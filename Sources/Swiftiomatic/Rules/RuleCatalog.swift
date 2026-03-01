/// Unified read-only facade that queries Suggest, Lint, and Format rule registries.
enum RuleCatalog {
  struct Entry: Codable, Sendable {
    let id: String
    let name: String
    let source: Source
    let description: String
    let isEnabled: Bool
    let isDeprecated: Bool
    let canAutoFix: Bool
    let isCrossFile: Bool
    let requiresSourceKit: Bool
  }

  /// All rules across all engines, sorted by source then id.
  static func allRules() -> [Entry] {
    var entries: [Entry] = []

    // Lint rules (AST-based, run through unified Analyzer)
    RuleRegistry.registerAllRulesOnce()
    let ruleList = RuleRegistry.shared.list
    for (identifier, ruleType) in ruleList.list {
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
  static func rules(for source: Source) -> [Entry] {
    allRules().filter { $0.source == source }
  }
}
