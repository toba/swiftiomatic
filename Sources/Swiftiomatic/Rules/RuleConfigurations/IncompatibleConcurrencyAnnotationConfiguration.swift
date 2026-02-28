
struct IncompatibleConcurrencyAnnotationConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "global_actors", postprocessor: { $0.insert("MainActor") })
    private(set) var globalActors = Set<String>()
    typealias Parent = IncompatibleConcurrencyAnnotationRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $globalActors.key.isEmpty {
            $globalActors.key = "global_actors"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$globalActors.key] {
            try globalActors.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
