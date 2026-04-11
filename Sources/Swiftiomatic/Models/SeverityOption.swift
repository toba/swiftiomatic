/// A rule configuration that allows specifying the desired severity level for violations.
struct SeverityOption<Parent: Rule>: SeverityBasedRuleOptions, InlinableOption,
  Sendable
{
  /// Configuration with an error severity.
  static var error: Self {
    Self(.error)
  }

  /// Configuration with a warning severity.
  static var warning: Self {
    Self(.warning)
  }

  @OptionElement(key: "severity")
  var severity = Severity.warning

  var severityConfiguration: Self {
    get { self }
    set { self = newValue }
  }

  /// Create a `SeverityOption` with the specified severity.
  ///
  /// - Parameters:
  ///   - severity: The severity that should be used when emitting violations.
  init(_ severity: Severity) {
    self.severity = severity
  }

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if let severityString = configuration[$severity.key] as? String {
      if let severity = Severity(rawValue: severityString.lowercased()) {
        self.severity = severity
      } else {
        throw .invalidConfiguration(ruleID: Parent.identifier)
      }
    } else {
      throw .nothingApplied(ruleID: Parent.identifier)
    }
  }

  /// Applies a value from a parent configuration element.
  /// Accepts either a `[String: Any]` dict or a bare severity string.
  mutating func apply(_ value: Any, ruleID: String) throws(SwiftiomaticError) {
    if let dict = value as? [String: Any] {
      try apply(configuration: dict)
    } else if let string = value as? String {
      try apply(configuration: [$severity.key: string])
    } else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
  }
}
