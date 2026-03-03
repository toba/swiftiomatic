struct TodoOptions: SeverityBasedRuleOptions {
    enum TodoKeyword: String, AcceptableByOptionElement, CaseIterable {
        case todo = "TODO"
        case fixme = "FIXME"
    }

    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(key: "only")
    private(set) var only = TodoKeyword.allCases
    typealias Parent = TodoRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$only.key] {
            try only.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
