/// A rule configuration that allows specifying the desired severity level for violations.
struct SeverityConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, InlinableOptionType, Sendable {
    /// Configuration with a warning severity.
    static var error: Self { Self(.error) }
    /// Configuration with an error severity.
    static var warning: Self { Self(.warning) }

    @ConfigurationElement(key: "severity")
    var severity = ViolationSeverity.warning

    var severityConfiguration: Self {
        self
    }

    /// Create a `SeverityConfiguration` with the specified severity.
    ///
    /// - parameter severity: The severity that should be used when emitting violations.
    init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    mutating func apply(configuration: Any) throws(Issue) {
        let configString = configuration as? String
        let configDict = configuration as? [String: Any]
        if let severityString: String = configString ?? configDict?[$severity.key] as? String {
            if let severity = ViolationSeverity(rawValue: severityString.lowercased()) {
                self.severity = severity
            } else {
                throw .invalidConfiguration(ruleID: Parent.identifier)
            }
        } else {
            throw .nothingApplied(ruleID: Parent.identifier)
        }
    }
}
