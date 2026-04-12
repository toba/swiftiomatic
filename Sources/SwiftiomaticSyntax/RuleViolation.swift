import Foundation

/// A value describing an instance of Swift source code that is considered invalid by a rule.
public struct RuleViolation: CustomStringConvertible, Codable, Hashable, Sendable {
  /// The identifier of the rule that generated this violation.
  package let ruleIdentifier: String

  /// The description of the rule that generated this violation.
  package let ruleDescription: String

  /// The name of the rule that generated this violation.
  package let ruleName: String

  /// The severity of this violation.
  package private(set) var severity: Severity

  /// The location of this violation.
  package private(set) var location: Location

  /// The justification for this violation.
  package let reason: ViolationMessage

  /// The confidence level of this violation.
  package let confidence: Confidence

  /// A suggested fix for the violation.
  package let suggestion: String?

  /// A printable description for this violation.
  public var description: String {
    // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
    [
      "\(location): ",
      "\(severity.rawValue): ",
      "\(ruleName) Violation: ",
      reason.text,
      " (\(ruleIdentifier))",
    ].joined()
  }

  /// Creates a `RuleViolation` from a ``Rule`` type's static metadata using a typed ``ViolationMessage``.
  ///
  /// - Parameters:
  ///   - ruleType: The rule type whose static metadata provides id, name, and summary.
  ///   - severity: The severity of this violation.
  ///   - location: The location of this violation.
  ///   - message: The typed message for this violation. Falls back to the rule's summary.
  package init<R: Rule>(
    ruleType _: R.Type,
    severity: Severity = .warning,
    location: Location,
    message: ViolationMessage?,
    confidence: Confidence = .high,
    suggestion: String? = nil,
  ) {
    ruleIdentifier = R.id
    ruleDescription = R.summary
    ruleName = R.name
    self.severity = severity
    self.location = location
    reason = message ?? ViolationMessage(stringLiteral: R.summary)
    self.confidence = confidence
    self.suggestion = suggestion
    #if DEBUG
      Self._validateReasonImpl?(reason, ruleIdentifier)
    #endif
  }

  /// Creates a `RuleViolation` from a ``Rule`` type's static metadata.
  ///
  /// - Parameters:
  ///   - ruleType: The rule type whose static metadata provides id, name, and summary.
  ///   - severity: The severity of this violation.
  ///   - location: The location of this violation.
  ///   - reason: The justification for this violation. Falls back to the rule's summary.
  package init<R: Rule>(
    ruleType _: R.Type,
    severity: Severity = .warning,
    location: Location,
    reason: String? = nil,
    confidence: Confidence = .high,
    suggestion: String? = nil,
  ) {
    ruleIdentifier = R.id
    ruleDescription = R.summary
    ruleName = R.name
    self.severity = severity
    self.location = location
    self.reason =
      reason.map { ViolationMessage(stringLiteral: $0) }
      ?? ViolationMessage(stringLiteral: R.summary)
    self.confidence = confidence
    self.suggestion = suggestion
    #if DEBUG
      Self._validateReasonImpl?(self.reason, ruleIdentifier)
    #endif
  }

  /// Creates a `RuleViolation` from an existential ``Rule`` type.
  package init(
    anyRuleType ruleType: any Rule.Type,
    severity: Severity = .warning,
    location: Location,
    reason: String? = nil,
    confidence: Confidence = .high,
    suggestion: String? = nil,
  ) {
    ruleIdentifier = ruleType.id
    ruleDescription = ruleType.summary
    ruleName = ruleType.name
    self.severity = severity
    self.location = location
    self.reason =
      reason.map { ViolationMessage(stringLiteral: $0) }
      ?? ViolationMessage(stringLiteral: ruleType.summary)
    self.confidence = confidence
    self.suggestion = suggestion
  }

  /// Returns the same violation, but with the `severity` that is passed in
  /// - Parameters:
  ///   - severity: the new severity to use in the modified violation
  package func with(severity: Severity) -> Self {
    var new = self
    new.severity = severity
    return new
  }

  /// Returns the same violation, but with the `location` that is passed in
  /// - Parameters:
  ///   - location: the new location to use in the modified violation
  package func with(location: Location) -> Self {
    var new = self
    new.location = location
    return new
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
  }

  #if DEBUG
    /// Hook for SwiftiomaticKit to install the real validation logic.
    ///
    /// The actual implementation (which requires `RuleRegistry`) lives in
    /// `SwiftiomaticKit/Extensions/RuleViolation+Diagnostic.swift`.
    package nonisolated(unsafe) static var _validateReasonImpl:
      ((ViolationMessage, String) -> Void)?
  #endif
}
