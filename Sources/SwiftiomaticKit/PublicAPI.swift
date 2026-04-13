public import SwiftiomaticSyntax

/// Public API surface for consumers outside the Swift package (e.g. Xcode Source Editor Extension).
/// Internal types remain `package` — this file exposes only what external targets need.
public enum Swiftiomatic {
  /// Format Swift source code using default settings.
  public static func format(_ source: String) throws -> String {
    try format(source, configuration: .default)
  }

  /// Format Swift source code using the given configuration.
  ///
  /// Runs the swift-format pretty-printer followed by correctable Swiftiomatic rules.
  public static func format(_ source: String, configuration: Configuration) throws -> String {
    // 1. swift-format pretty-printer
    var result = try configuration.makeFormatEngine().format(source)

    // 2. Correctable Swiftiomatic rules
    RuleRegistry.registerAllRulesOnce()
    let rules = RuleResolver.loadRules(
      enabled: configuration.enabledLintRules.isEmpty ? nil : Set(configuration.enabledLintRules),
      disabled: Set(configuration.disabledLintRules),
      ruleConfigs: configuration.lintRuleConfigs,
      formatDefaults: ["max_width": configuration.formatMaxWidth],
      skipAnalyzerRules: true
    )
    let correctable = rules.filter {
      type(of: $0).isCorrectable && !type(of: $0).runsWithSourceKit
    }

    if correctable.isNotEmpty {
      let file = SwiftSource(contents: result)
      for rule in correctable {
        _ = rule.correct(file: file)
      }
      result = file.contents
    }

    return result
  }

  /// Run lint-scope rules on a single source string and return diagnostics sorted by location.
  public static func lint(_ source: String, fileName _: String = "<stdin>") -> [Diagnostic] {
    RuleRegistry.registerAllRulesOnce()
    let file = SwiftSource(contents: source)

    let rules = RuleResolver.loadRules(skipAnalyzerRules: true)
    let lintRules = rules.filter { type(of: $0).ruleScope == .lint }

    var diagnostics: [Diagnostic] = []
    for rule in lintRules {
      let violations = rule.validate(file: file)
      for violation in violations {
        diagnostics.append(violation.toDiagnostic())
      }
    }
    return diagnostics.sorted()
  }

  /// Returns metadata for every registered rule, sorted by identifier.
  public static func ruleCatalog() -> [RuleConfigurationEntry] {
    RuleCatalog.allEntries().sorted { $0.id < $1.id }
  }

  /// Load a configuration from a YAML file at the given path.
  public static func loadConfiguration(from path: String) throws -> Configuration {
    try Configuration.loadUnified(from: path)
  }

  /// Save a configuration to a YAML file at the given path.
  public static func saveConfiguration(_ config: Configuration, to path: String) throws {
    try config.writeYAML(to: path)
  }
}
