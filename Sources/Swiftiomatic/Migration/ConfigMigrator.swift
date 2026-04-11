import Foundation

/// A warning generated during config migration
public struct MigrationWarning: Equatable, Sendable {
  /// The source tool (e.g. "SwiftLint", "SwiftFormat")
  public let source: String
  /// The original rule or setting identifier
  public let identifier: String
  /// Human-readable description of the issue
  public let message: String
}

/// Result of migrating one or more config files
public struct MigrationResult: Sendable {
  /// The migrated configuration, ready to write as `.swiftiomatic.yaml`
  public var configuration: Configuration
  /// Warnings about unmapped rules, ambiguous settings, etc.
  public var warnings: [MigrationWarning]
  /// Summary counts
  public var mappedRuleCount: Int
  public var unmappedRuleCount: Int

  public init(
    configuration: Configuration,
    warnings: [MigrationWarning],
    mappedRuleCount: Int,
    unmappedRuleCount: Int,
  ) {
    self.configuration = configuration
    self.warnings = warnings
    self.mappedRuleCount = mappedRuleCount
    self.unmappedRuleCount = unmappedRuleCount
  }
}

/// Converts SwiftLint and SwiftFormat configs to Swiftiomatic configuration
public enum ConfigMigrator {
  /// Migrate a SwiftLint configuration
  ///
  /// - Parameters:
  ///   - swiftlint: The parsed SwiftLint configuration.
  /// - Returns: The migration result with a ``Configuration`` and any warnings.
  public static func migrate(swiftlint: SwiftLintConfig) -> MigrationResult {
    var config = Configuration()
    var warnings: [MigrationWarning] = []
    var mapped = 0
    var unmapped = 0

    // Map disabled rules
    for ruleID in swiftlint.disabledRules {
      switch RuleMapping.swiftlint(ruleID) {
      case .exact(let id):
        config.disabledLintRules.append(id)
        mapped += 1
      case .renamed(let old, let new):
        config.disabledLintRules.append(new)
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: old,
            message: "Renamed to '\(new)'",
          ))
        mapped += 1
      case .removed(let reason):
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: ruleID,
            message: "Removed: \(reason)",
          ))
      case .unmapped:
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: ruleID,
            message: "No Swiftiomatic equivalent found",
          ))
        unmapped += 1
      }
    }

    // Map opt-in / only rules
    let enabledRuleIDs =
      swiftlint.onlyRules.isEmpty
      ? swiftlint.optInRules
      : swiftlint.onlyRules
    for ruleID in enabledRuleIDs {
      switch RuleMapping.swiftlint(ruleID) {
      case .exact(let id):
        config.enabledLintRules.append(id)
        mapped += 1
      case .renamed(let old, let new):
        config.enabledLintRules.append(new)
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: old,
            message: "Renamed to '\(new)'",
          ))
        mapped += 1
      case .removed(let reason):
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: ruleID,
            message: "Removed: \(reason)",
          ))
      case .unmapped:
        warnings.append(
          MigrationWarning(
            source: "SwiftLint",
            identifier: ruleID,
            message: "No Swiftiomatic equivalent found",
          ))
        unmapped += 1
      }
    }

    // Map analyzer rules as enabled
    for ruleID in swiftlint.analyzerRules {
      switch RuleMapping.swiftlint(ruleID) {
      case .exact(let id):
        config.enabledLintRules.append(id)
        mapped += 1
      case .renamed(_, let new):
        config.enabledLintRules.append(new)
        mapped += 1
      case .removed, .unmapped:
        break
      }
    }

    // Map per-rule configurations
    for (ruleID, value) in swiftlint.ruleConfigs {
      let mapping = RuleMapping.swiftlint(ruleID)
      guard let smID = mapping.swiftiomaticID else { continue }
      if let cfgValue = ConfigValue(value) {
        config.lintRuleConfigs[smID] = cfgValue
      }
    }

    // Advisory warnings for included/excluded paths
    if !swiftlint.includedPaths.isEmpty {
      warnings.append(
        MigrationWarning(
          source: "SwiftLint",
          identifier: "included",
          message:
            "Included paths (\(swiftlint.includedPaths.joined(separator: ", "))) — pass as arguments to swiftiomatic instead",
        ))
    }
    if !swiftlint.excludedPaths.isEmpty {
      warnings.append(
        MigrationWarning(
          source: "SwiftLint",
          identifier: "excluded",
          message:
            "Excluded paths (\(swiftlint.excludedPaths.joined(separator: ", "))) — use --exclude flag instead",
        ))
    }

    return MigrationResult(
      configuration: config,
      warnings: warnings,
      mappedRuleCount: mapped,
      unmappedRuleCount: unmapped,
    )
  }

  /// Migrate a SwiftFormat configuration
  ///
  /// - Parameters:
  ///   - swiftformat: The parsed SwiftFormat configuration.
  /// - Returns: The migration result.
  public static func migrate(swiftformat: SwiftFormatConfig) -> MigrationResult {
    var config = Configuration()
    var warnings: [MigrationWarning] = []
    var mapped = 0
    var unmapped = 0

    // Map disabled rules
    for ruleName in swiftformat.disabledRules {
      switch RuleMapping.swiftformat(ruleName) {
      case .exact(let id):
        config.disabledLintRules.append(id)
        mapped += 1
      case .renamed(_, let new):
        config.disabledLintRules.append(new)
        mapped += 1
      case .removed(let reason):
        warnings.append(
          MigrationWarning(
            source: "SwiftFormat",
            identifier: ruleName,
            message: "Removed: \(reason)",
          ))
      case .unmapped:
        warnings.append(
          MigrationWarning(
            source: "SwiftFormat",
            identifier: ruleName,
            message: "No Swiftiomatic equivalent found",
          ))
        unmapped += 1
      }
    }

    // Map enabled rules
    for ruleName in swiftformat.enabledRules {
      switch RuleMapping.swiftformat(ruleName) {
      case .exact(let id):
        config.enabledLintRules.append(id)
        mapped += 1
      case .renamed(_, let new):
        config.enabledLintRules.append(new)
        mapped += 1
      case .removed(let reason):
        warnings.append(
          MigrationWarning(
            source: "SwiftFormat",
            identifier: ruleName,
            message: "Removed: \(reason)",
          ))
      case .unmapped:
        warnings.append(
          MigrationWarning(
            source: "SwiftFormat",
            identifier: ruleName,
            message: "No Swiftiomatic equivalent found",
          ))
        unmapped += 1
      }
    }

    // Map formatting options
    if let indent = swiftformat.indent {
      if indent == "tab" || indent == "tabs" {
        config.formatIndent = "\t"
      } else if let width = Int(indent) {
        config.formatIndent = String(repeating: " ", count: width)
      }
    }

    if let maxWidth = swiftformat.maxWidth {
      config.formatMaxWidth = maxWidth
    }

    if let commas = swiftformat.commas {
      config.formatTrailingCommas = commas == "always"
    }

    if let version = swiftformat.swiftVersion {
      if let parsed = Version(rawValue: version) {
        config.formatSwiftVersion = parsed
      }
    }

    return MigrationResult(
      configuration: config,
      warnings: warnings,
      mappedRuleCount: mapped,
      unmappedRuleCount: unmapped,
    )
  }

  /// Merge results from SwiftLint and SwiftFormat migrations
  ///
  /// - Parameters:
  ///   - swiftlint: The SwiftLint migration result.
  ///   - swiftformat: The SwiftFormat migration result.
  /// - Returns: A combined migration result.
  public static func merge(
    swiftlint: MigrationResult,
    swiftformat: MigrationResult,
  ) -> MigrationResult {
    var config = swiftlint.configuration

    // Merge SwiftFormat disabled rules (dedup)
    let existingDisabled = Set(config.disabledLintRules)
    for rule in swiftformat.configuration.disabledLintRules where !existingDisabled.contains(rule) {
      config.disabledLintRules.append(rule)
    }

    // Merge SwiftFormat enabled rules (dedup)
    let existingEnabled = Set(config.enabledLintRules)
    for rule in swiftformat.configuration.enabledLintRules where !existingEnabled.contains(rule) {
      config.enabledLintRules.append(rule)
    }

    // SwiftFormat format settings override SwiftLint's (SwiftFormat is the formatting authority)
    let sfConfig = swiftformat.configuration
    let defaults = Configuration.default
    if sfConfig.formatIndent != defaults.formatIndent {
      config.formatIndent = sfConfig.formatIndent
    }
    if sfConfig.formatMaxWidth != defaults.formatMaxWidth {
      config.formatMaxWidth = sfConfig.formatMaxWidth
    }
    if sfConfig.formatTrailingCommas != defaults.formatTrailingCommas {
      config.formatTrailingCommas = sfConfig.formatTrailingCommas
    }

    return MigrationResult(
      configuration: config,
      warnings: swiftlint.warnings + swiftformat.warnings,
      mappedRuleCount: swiftlint.mappedRuleCount + swiftformat.mappedRuleCount,
      unmappedRuleCount: swiftlint.unmappedRuleCount + swiftformat.unmappedRuleCount,
    )
  }
}
