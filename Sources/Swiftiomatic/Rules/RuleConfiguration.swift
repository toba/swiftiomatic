/// A configuration value for a rule to allow users to modify its behavior.
protocol RuleConfiguration: Equatable, Sendable {
  /// The type of the rule that's using this configuration.
  associatedtype Parent: Rule

  /// A description for this configuration's parameters. It can be built using the annotated result builder.
  @RuleConfigurationDescriptionBuilder
  var parameterDescription: RuleConfigurationDescription? { get }

  /// Apply an untyped configuration to the current value.
  ///
  /// - parameter configuration: The untyped configuration value to apply.
  ///
  /// - throws: Throws if the configuration is not in the expected format.
  mutating func apply(configuration: [String: Any]) throws(Issue)

  /// Run a sanity check on the configuration, perform optional postprocessing steps and/or warn about potential
  /// issues.
  mutating func validate() throws(Issue)
}

/// A configuration for a rule that allows to configure at least the severity.
protocol SeverityBasedRuleConfiguration: RuleConfiguration {
  /// The configuration of a rule's severity.
  var severityConfiguration: SeverityConfiguration<Parent> { get set }
}

extension SeverityBasedRuleConfiguration {
  /// The severity of a rule.
  var severity: ViolationSeverity {
    severityConfiguration.severity
  }

  /// Apply severity from the configuration if present, silently ignoring when absent.
  mutating func applySeverityIfPresent(_ configuration: [String: Any]) throws(Issue) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable — severity is optional.
    }
  }
}

extension RuleConfiguration {
  var parameterDescription: RuleConfigurationDescription? {
    nil
  }

  // sm:disable:next unneeded_throws_rethrows
  func validate() {
    // Do nothing by default.
  }
}

extension RuleConfiguration {
  /// All keys supported by this configuration.
  var supportedKeys: Set<String> {
    Set(RuleConfigurationDescription.from(configuration: self).allowedKeys())
  }

  /// Emit a warning for any unrecognized keys in the configuration.
  func warnAboutUnknownKeys(in configuration: [String: Any]) {
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
  }
}
