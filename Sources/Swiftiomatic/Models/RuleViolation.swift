import Foundation

/// A value describing an instance of Swift source code that is considered invalid by a rule.
public struct RuleViolation: CustomStringConvertible, Codable, Hashable, Sendable {
    /// The identifier of the rule that generated this violation.
    let ruleIdentifier: String

    /// The description of the rule that generated this violation.
    let ruleDescription: String

    /// The name of the rule that generated this violation.
    let ruleName: String

    /// The severity of this violation.
    private(set) var severity: Severity

    /// The location of this violation.
    private(set) var location: Location

    /// The justification for this violation.
    let reason: ViolationMessage

    /// The confidence level of this violation.
    let confidence: Confidence

    /// A suggested fix for the violation.
    let suggestion: String?

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
    init<R: Rule>(
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
        Self.validateReason(reason, ruleIdentifier: ruleIdentifier)
        #endif
    }

    /// Creates a `RuleViolation` from a ``Rule`` type's static metadata.
    ///
    /// - Parameters:
    ///   - ruleType: The rule type whose static metadata provides id, name, and summary.
    ///   - severity: The severity of this violation.
    ///   - location: The location of this violation.
    ///   - reason: The justification for this violation. Falls back to the rule's summary.
    init<R: Rule>(
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
        Self.validateReason(self.reason, ruleIdentifier: ruleIdentifier)
        #endif
    }

    /// Creates a `RuleViolation` from an existential ``Rule`` type.
    init(
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
    func with(severity: Severity) -> Self {
        var new = self
        new.severity = severity
        return new
    }

    /// Returns the same violation, but with the `location` that is passed in
    /// - Parameters:
    ///   - location: the new location to use in the modified violation
    func with(location: Location) -> Self {
        var new = self
        new.location = location
        return new
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    /// Convert to the unified Diagnostic output type.
    func toDiagnostic() -> Diagnostic {
        let ruleType = RuleRegistry.shared.rule(forID: ruleIdentifier)
        let isCorrectableType = ruleType.map { $0 is any CorrectableRule.Type } ?? false
        return Diagnostic(
            ruleID: ruleIdentifier,
            source: .lint,
            severity: severity,
            confidence: confidence,
            file: location.file ?? "<unknown>",
            line: location.line ?? 0,
            column: location.column ?? 0,
            message: reason.text,
            suggestion: suggestion,
            canAutoFix: isCorrectableType,
        )
    }

    #if DEBUG
    private static func validateReason(_ reason: ViolationMessage, ruleIdentifier: String) {
        if reason.text.trimmingTrailingCharacters(in: .whitespaces).last == ".",
           RuleRegistry.shared.rule(forID: ruleIdentifier) != nil
        {
            Console.fatalError(
                """
                Reasons shall not end with a period. Got "\(reason
                    .text)". Either rewrite the rule's summary \
                or set a custom reason in the RuleViolation's constructor.
                """,
            )
        }
    }
    #endif
}
