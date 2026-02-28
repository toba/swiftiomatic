/// Instantiates lint rules based on enable/disable lists and per-rule configuration.
///
/// Replaces the Configuration+RulesWrapper layer from the vendored SwiftLint orchestration.
enum RuleLoader {
  /// Instantiate all registered rules with optional per-rule config overrides.
  ///
  /// - Parameters:
  ///   - enabled: Explicit set of rule IDs to enable (opt-in rules need this). `nil` = all non-OptIn.
  ///   - disabled: Rule IDs to skip.
  ///   - onlyRules: If non-empty, ONLY these rules run (overrides enabled/disabled).
  ///   - ruleConfigs: Per-rule configuration dictionaries from `.swiftiomatic.yaml`.
  ///   - skipAnalyzerRules: If true, skip rules that require compiler arguments (AnalyzerRule).
  static func loadRules(
    enabled: Set<String>? = nil,
    disabled: Set<String> = [],
    onlyRules: Set<String> = [],
    ruleConfigs: [String: Any] = [:],
    skipAnalyzerRules: Bool = true,
  ) -> [any Rule] {
    RuleRegistry.registerAllRulesOnce()
    let ruleList = RuleRegistry.shared.list

    return ruleList.list.compactMap { identifier, ruleType -> (any Rule)? in
      // --only-rule overrides everything
      if !onlyRules.isEmpty {
        guard onlyRules.contains(identifier) else { return nil }
      } else {
        // Skip disabled rules
        guard !disabled.contains(identifier) else { return nil }

        // Skip opt-in rules unless explicitly enabled
        if ruleType is any OptInRule.Type {
          guard enabled?.contains(identifier) ?? false else { return nil }
        }
      }

      // Skip analyzer rules when we don't have compiler arguments
      if skipAnalyzerRules, ruleType is any AnalyzerRule.Type {
        return nil
      }

      // Skip SuperfluousDisableCommandRule — depends on the Lint orchestration layer
      if ruleType is SuperfluousDisableCommandRule.Type {
        return nil
      }

      // Instantiate with config override if provided
      if let config = ruleConfigs[identifier] {
        return try? ruleType.init(configuration: config)
      }
      return ruleType.init()
    }
  }
}
