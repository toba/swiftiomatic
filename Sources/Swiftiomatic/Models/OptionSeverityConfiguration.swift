/// A rule configuration that allows to disable (`off`) an option of a rule or specify its severity level in which
/// case it's active.
struct OptionSeverityConfiguration<Parent: Rule>: RuleOptions,
    AcceptableByOptionElement,
    Sendable
{
    /// Configuration with an error severity.
    static var error: Self {
        Self(optionSeverity: .error)
    }

    /// Configuration with a warning severity.
    static var warning: Self {
        Self(optionSeverity: .warning)
    }

    /// Configuration disabling an option.
    static var off: Self {
        Self(optionSeverity: .off)
    }

    enum OptionSeverity: String {
        case warning, error, off
    }

    private var optionSeverity: OptionSeverity

    /// The `OptionSeverityConfiguration` mapped to a usually used `Severity`. It's `nil` if the option
    /// is set to `off`.
    var severity: Severity? {
        Severity(rawValue: optionSeverity.rawValue)
    }

    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        guard let configString = configuration["severity"] as? String,
              let optionSeverity = OptionSeverity(rawValue: configString.lowercased())
        else {
            throw .invalidConfiguration(ruleID: Parent.identifier)
        }
        self.optionSeverity = optionSeverity
    }

    func asOption() -> OptionType {
        .symbol(optionSeverity.rawValue)
    }
}
