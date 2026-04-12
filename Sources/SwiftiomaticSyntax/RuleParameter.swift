/// A configuration parameter for rules.
@preconcurrency
package struct RuleParameter<T: Equatable & Sendable>: Equatable, Sendable {
  /// The severity that should be assigned to the violation of this parameter's value is met.
  package let severity: Severity
  /// The value to configure the rule.
  package let value: T

  package init(severity: Severity, value: T) {
    self.severity = severity
    self.value = value
  }
}
