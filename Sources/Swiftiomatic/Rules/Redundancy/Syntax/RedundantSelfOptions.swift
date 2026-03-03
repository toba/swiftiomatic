struct RedundantSelfOptions: SeverityBasedRuleOptions {
    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(key: "keep_in_initializers")
    private(set) var keepInInitializers = false
    @OptionElement(key: "only_in_closures")
    private(set) var onlyInClosures = true
    typealias Parent = RedundantSelfRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$keepInInitializers.key] {
            try keepInInitializers.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$onlyInClosures.key] {
            try onlyInClosures.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
