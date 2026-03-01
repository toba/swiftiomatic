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
    let reason: String

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
            reason,
            " (\(ruleIdentifier))",
        ].joined()
    }

    /// Creates a `RuleViolation` by specifying its properties directly.
    ///
    /// - Parameters:
    ///   - ruleDescription: The description of the rule that generated this violation.
    ///   - severity: The severity of this violation.
    ///   - location: The location of this violation.
    ///   - reason: The justification for this violation. If not specified the rule's description will
    ///     be used.
    init(
        ruleDescription: RuleDescription,
        severity: Severity = .warning,
        location: Location,
        reason: String? = nil,
        confidence: Confidence = .high,
        suggestion: String? = nil,
    ) {
        ruleIdentifier = ruleDescription.identifier
        self.ruleDescription = ruleDescription.description
        ruleName = ruleDescription.name
        self.severity = severity
        self.location = location
        self.reason = reason ?? ruleDescription.description
        self.confidence = confidence
        self.suggestion = suggestion
        #if DEBUG
        if self.reason.trimmingTrailingCharacters(in: .whitespaces).last == ".",
           RuleRegistry.shared.rule(forID: ruleIdentifier) != nil
        {
            Console.fatalError(
                """
                Reasons shall not end with a period. Got "\(self
                    .reason)". Either rewrite the rule's description \
                or set a custom reason in the RuleViolation's constructor.
                """,
            )
        }
        #endif
    }

    /// Creates a `RuleViolation` from a ``RuleConfiguration`` source.
    ///
    /// - Parameters:
    ///   - configuration: The rule's configuration metadata.
    ///   - severity: The severity of this violation.
    ///   - location: The location of this violation.
    ///   - reason: The justification for this violation. Falls back to the rule's summary.
    init(
        configuration: some RuleConfiguration,
        severity: Severity = .warning,
        location: Location,
        reason: String? = nil,
        confidence: Confidence = .high,
        suggestion: String? = nil,
    ) {
        ruleIdentifier = configuration.id
        ruleDescription = configuration.summary
        ruleName = configuration.name
        self.severity = severity
        self.location = location
        self.reason = reason ?? configuration.summary
        self.confidence = confidence
        self.suggestion = suggestion
        #if DEBUG
        if self.reason.trimmingTrailingCharacters(in: .whitespaces).last == ".",
           RuleRegistry.shared.rule(forID: ruleIdentifier) != nil
        {
            Console.fatalError(
                """
                Reasons shall not end with a period. Got "\(self
                    .reason)". Either rewrite the rule's summary \
                or set a custom reason in the RuleViolation's constructor.
                """,
            )
        }
        #endif
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
            message: reason,
            suggestion: suggestion,
            canAutoFix: isCorrectableType,
        )
    }
}
