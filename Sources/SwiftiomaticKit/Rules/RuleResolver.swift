/// Instantiates lint rules based on enable/disable lists and per-rule configuration
///
/// Replaces the ``Configuration/RuleSelection`` layer from the vendored lint orchestration.
public enum RuleResolver {
  /// Instantiate all registered rules with optional per-rule config overrides
  ///
  /// - Parameters:
  ///   - enabled: Explicit set of rule IDs to enable (opt-in rules need this). `nil` means all default rules.
  ///   - disabled: Rule IDs to skip.
  ///   - onlyRules: If non-empty, ONLY these rules run (overrides enabled/disabled).
  ///   - ruleConfigs: Per-rule configuration dictionaries from `.swiftiomatic.yaml`.
  ///   - formatDefaults: Global `format:` values (e.g. `["max_width": 120]`) injected into
  ///     rules conforming to ``FormatAwareRule``. Per-rule config takes precedence.
  ///   - skipAnalyzerRules: If `true`, skip rules that require compiler arguments.
  /// - Returns: The instantiated and configured rules.
  public static func loadRules(
    enabled: Set<String>? = nil,
    disabled: Set<String> = [],
    onlyRules: Set<String> = [],
    ruleConfigs: [String: ConfigValue] = [:],
    formatDefaults: [String: Any] = [:],
    skipAnalyzerRules: Bool = true,
  ) -> [any Rule] {
    RuleRegistry.registerAllRulesOnce()
    let ruleList = RuleRegistry.shared.list

    return ruleList.rules.compactMap { identifier, ruleType -> (any Rule)? in
      // --only-rule overrides everything
      if !onlyRules.isEmpty {
        guard onlyRules.contains(identifier) else { return nil }
      } else {
        // Skip disabled rules
        guard !disabled.contains(identifier) else { return nil }

        // Skip opt-in rules unless explicitly enabled
        if ruleType.isOptIn {
          guard enabled?.contains(identifier) ?? false else { return nil }
        }
      }

      // Skip analyzer rules when we don't have compiler arguments
      if skipAnalyzerRules, ruleType.runsWithCompilerArguments { return nil }

      // Skip SuperfluousDisableCommandRule — depends on the Lint orchestration layer
      if ruleType is SuperfluousDisableCommandRule.Type { return nil }

      // Build effective config: format defaults (filtered to declared keys) + rule overrides
      let ruleConfig = ruleConfigs[identifier]
      let effectiveConfig = Self.mergeFormatDefaults(
        formatDefaults, into: ruleConfig, for: ruleType,
      )

      if let effectiveConfig {
        return try? ruleType.init(configuration: effectiveConfig)
      }
      return ruleType.init()
    }
  }

  /// Merge global format defaults into a rule's config for ``FormatAwareRule`` conformers.
  ///
  /// Returns `nil` when no configuration is needed (no rule config and rule doesn't use format defaults).
  private static func mergeFormatDefaults(
    _ formatDefaults: [String: Any],
    into ruleConfig: ConfigValue?,
    for ruleType: any Rule.Type,
  ) -> Any? {
    // Only inject for FormatAwareRule conformers
    guard let formatAwareType = ruleType as? any FormatAwareRule.Type,
      !formatDefaults.isEmpty
    else {
      return ruleConfig?.asAny
    }

    // Filter format defaults to keys the rule declares
    let keys = formatAwareType.formatConfigKeys
    var merged: [String: Any] = formatDefaults.filter { keys.contains($0.key) }
    guard !merged.isEmpty || ruleConfig != nil else { return nil }

    // Rule-specific config takes precedence
    if let dict = ruleConfig?.asAny as? [String: Any] {
      merged.merge(dict) { _, ruleValue in ruleValue }
    }

    return merged.isEmpty ? ruleConfig?.asAny : merged
  }
}
