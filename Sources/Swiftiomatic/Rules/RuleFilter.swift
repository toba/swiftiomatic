/// Filters the full ``RuleList`` according to enabled/disabled/correctable criteria
final class RuleFilter {
  /// Options controlling which categories of rules to exclude
  struct ExcludingOptions: OptionSet {
    let rawValue: Int

    /// Exclude rules that are currently enabled
    static let enabled = Self(rawValue: 1 << 0)
    /// Exclude rules that are currently disabled
    static let disabled = Self(rawValue: 1 << 1)
    /// Exclude rules that cannot auto-correct violations
    static let uncorrectable = Self(rawValue: 1 << 2)
  }

  private let allRules: RuleList
  private let enabledRules: [any Rule]

  /// Create a filter over the given rule list and currently enabled rules
  ///
  /// - Parameters:
  ///   - allRules: The complete rule list to filter against.
  ///   - enabledRules: The rules currently active in the configuration.
  init(allRules: RuleList = RuleRegistry.shared.list, enabledRules: [any Rule]) {
    self.allRules = allRules
    self.enabledRules = enabledRules
  }

  /// Return a ``RuleList`` with the specified categories excluded
  ///
  /// - Parameters:
  ///   - excludingOptions: The categories of rules to remove.
  /// - Returns: A filtered ``RuleList``.
  func rules(excluding excludingOptions: ExcludingOptions) -> RuleList {
    if excludingOptions.isEmpty {
      return allRules
    }

    let filtered: [any Rule.Type] = allRules.rules.compactMap { ruleID, ruleType in
      let enabledRule = enabledRules.first { rule in
        type(of: rule).identifier == ruleID
      }
      let isRuleEnabled = enabledRule != nil

      if excludingOptions.contains(.enabled), isRuleEnabled {
        return nil
      }
      if excludingOptions.contains(.disabled), !isRuleEnabled {
        return nil
      }
      if excludingOptions.contains(.uncorrectable), !ruleType.isCorrectable {
        return nil
      }

      return ruleType
    }

    return RuleList(rules: filtered)
  }
}
