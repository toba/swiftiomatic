
struct ImplicitOptionalInitializationConfiguration: SeverityBasedRuleConfiguration { // swiftlint:disable:this type_name
    enum Style: String, AcceptableByConfigurationElement {
        case always
        case never
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "style")
    private(set) var style: Style = .always
    typealias Parent = ImplicitOptionalInitializationRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $style.key.isEmpty {
            $style.key = "style"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$style.key] {
            try style.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
