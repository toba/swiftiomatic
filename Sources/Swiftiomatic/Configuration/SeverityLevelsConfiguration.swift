/// A rule configuration that allows specifying thresholds for `warning` and `error` severities
struct SeverityLevelsConfiguration<Parent: Rule>: RuleOptions, InlinableOption, Sendable {
    /// The threshold for a violation to be a warning
    @ConfigurationElement(key: "warning")
    var warning = 12
    /// The threshold for a violation to be an error
    @ConfigurationElement(key: "error")
    var error: Int?

    /// Create a ``SeverityLevelsConfiguration`` with the specified thresholds
    ///
    /// - Parameters:
    ///   - warning: The threshold for a violation to be a warning.
    ///   - error: The threshold for a violation to be an error.
    init(warning: Int, error: Int? = nil) {
        self.warning = warning
        self.error = error
    }

    /// The rule parameters that define the thresholds that should map to each severity
    var params: [RuleParameter<Int>] {
        if let error {
            return [
                RuleParameter(severity: .error, value: error),
                RuleParameter(severity: .warning, value: warning),
            ]
        }
        return [RuleParameter(severity: .warning, value: warning)]
    }

    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        if let rawArray = configuration["_values"] as? [Int], rawArray.isNotEmpty {
            warning = rawArray[0]
            error = (rawArray.count > 1) ? rawArray[1] : nil
        } else {
            let warningValue: Any? = configuration[$warning.key]
            if let warningValue {
                if let warning = warningValue as? Int {
                    self.warning = warning
                } else {
                    throw .invalidConfiguration(ruleID: Parent.identifier)
                }
            }
            if let errorValue = configuration[$error.key] {
                if let error = errorValue as? Int {
                    self.error = error
                } else {
                    throw .invalidConfiguration(ruleID: Parent.identifier)
                }
            } else if warningValue != nil {
                error = nil
            }
        }
    }
}
