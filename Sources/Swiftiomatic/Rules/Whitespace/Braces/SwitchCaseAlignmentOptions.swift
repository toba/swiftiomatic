struct SwitchCaseAlignmentOptions: SeverityBasedRuleOptions {
    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(key: "indented_cases")
    private(set) var indentedCases = false
    @OptionElement(key: "ignore_one_liners")
    private(set) var ignoreOneLiners = false
    typealias Parent = SwitchCaseAlignmentRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$indentedCases.key] {
            try indentedCases.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreOneLiners.key] {
            try ignoreOneLiners.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
