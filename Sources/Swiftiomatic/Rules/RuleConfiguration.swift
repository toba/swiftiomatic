/// A configuration value for a rule to allow users to modify its behavior
public protocol RuleConfiguration: Equatable, Sendable {
  /// The type of the rule that uses this configuration
  associatedtype Parent: Rule

  /// A description for this configuration's parameters, built using the annotated result builder
  @RuleConfigurationDescriptionBuilder
  var parameterDescription: RuleConfigurationDescription? { get }

  /// Apply an untyped configuration to the current value
  ///
  /// - Parameters:
  ///   - configuration: The untyped configuration value to apply.
  /// - Throws: ``SwiftiomaticError`` if the configuration is not in the expected format.
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError)

  /// Run a sanity check on the configuration and perform optional post-processing
  mutating func validate() throws(SwiftiomaticError)
}

/// A configuration for a rule that allows configuring at least the severity
protocol SeverityBasedRuleConfiguration: RuleConfiguration {
  /// The configuration of a rule's severity
  var severityConfiguration: SeverityConfiguration<Parent> { get set }
}

extension SeverityBasedRuleConfiguration {
  /// The severity of a rule
  var severity: Severity {
    severityConfiguration.severity
  }

  /// Apply severity from the configuration if present, silently ignoring when absent
  ///
  /// - Parameters:
  ///   - configuration: The untyped configuration dictionary.
  mutating func applySeverityIfPresent(_ configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier) {
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
  /// All keys supported by this configuration
  var supportedKeys: Set<String> {
    Set(RuleConfigurationDescription.from(configuration: self).allowedKeys())
  }

  /// Emit a warning for any unrecognized keys in the configuration
  ///
  /// - Parameters:
  ///   - configuration: The configuration dictionary to check for unknown keys.
  func warnAboutUnknownKeys(in configuration: [String: Any]) {
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      SwiftiomaticError.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
  }
}
