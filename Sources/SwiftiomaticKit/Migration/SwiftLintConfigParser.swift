import Foundation
import Yams

/// Parsed representation of a `.swiftlint.yml` configuration file
public struct SwiftLintConfig: Sendable {
  /// Rules explicitly disabled
  public var disabledRules: [String] = []
  /// Opt-in rules explicitly enabled
  public var optInRules: [String] = []
  /// When set, only these rules run (overrides disabled/opt-in)
  public var onlyRules: [String] = []
  /// Analyzer rules (require compiler arguments)
  public var analyzerRules: [String] = []
  /// Paths to include
  public var includedPaths: [String] = []
  /// Paths to exclude
  public var excludedPaths: [String] = []
  /// Per-rule configuration (raw YAML values)
  public var ruleConfigs: [String: ConfigValue] = [:]
}

/// Parses SwiftLint `.swiftlint.yml` configuration files
public enum SwiftLintConfigParser {
  /// Known top-level keys in `.swiftlint.yml`
  private static let topLevelKeys: Set<String> = [
    "disabled_rules", "opt_in_rules", "only_rules", "analyzer_rules",
    "included", "excluded", "indentation", "cache_path",
    "reporter", "allow_zero_lintable_files",
    "strict", "baseline", "write_baseline",
    "check_for_updates",
  ]

  /// Parse a `.swiftlint.yml` file at the given path
  ///
  /// - Parameters:
  ///   - path: File system path to the `.swiftlint.yml` file.
  /// - Returns: The parsed ``SwiftLintConfig``.
  public static func parse(at path: String) throws -> SwiftLintConfig {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return try parse(yaml: contents)
  }

  /// Parse a `.swiftlint.yml` from a YAML string
  ///
  /// - Parameters:
  ///   - yaml: The YAML string to parse.
  /// - Returns: The parsed ``SwiftLintConfig``.
  public static func parse(yaml: String) throws -> SwiftLintConfig {
    guard let dict = try Yams.load(yaml: yaml) as? [String: Any] else {
      return SwiftLintConfig()
    }
    return parse(dict: dict)
  }

  /// Parse from an already-loaded dictionary
  static func parse(dict: [String: Any]) -> SwiftLintConfig {
    var config = SwiftLintConfig()

    config.disabledRules = stringArray(dict["disabled_rules"])
    config.optInRules = stringArray(dict["opt_in_rules"])
    config.onlyRules = stringArray(dict["only_rules"])
    config.analyzerRules = stringArray(dict["analyzer_rules"])
    config.includedPaths = stringArray(dict["included"])
    config.excludedPaths = stringArray(dict["excluded"])

    // Collect per-rule configurations (any key not in topLevelKeys)
    for (key, value) in dict where !topLevelKeys.contains(key) {
      if let configValue = ConfigValue(value) {
        config.ruleConfigs[key] = configValue
      }
    }

    return config
  }

  private static func stringArray(_ value: Any?) -> [String] {
    (value as? [String]) ?? []
  }
}
