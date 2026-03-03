struct FileNameNoSpaceOptions: SeverityBasedRuleOptions {
    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>.warning
    @OptionElement(key: "excluded")
    private(set) var excluded = Set<String>()
    typealias Parent = FileNameNoSpaceRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$excluded.key] {
            try excluded.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
