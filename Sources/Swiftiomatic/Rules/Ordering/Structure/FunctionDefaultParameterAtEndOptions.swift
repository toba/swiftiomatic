struct FunctionDefaultParameterAtEndOptions: SeverityBasedRuleOptions {
    // sm:disable:previous type_name

    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(key: "ignore_first_isolation_inheritance_parameter")
    private(set) var ignoreFirstIsolationInheritanceParameter = true
    typealias Parent = FunctionDefaultParameterAtEndRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$ignoreFirstIsolationInheritanceParameter.key] {
            try ignoreFirstIsolationInheritanceParameter.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
