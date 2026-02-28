struct ComputedAccessorsOrderConfiguration: SeverityBasedRuleConfiguration {
    enum Order: String, AcceptableByConfigurationElement {
        case getSet = "get_set"
        case setGet = "set_get"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order = Order.getSet
    typealias Parent = ComputedAccessorsOrderRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $order.key.isEmpty {
            $order.key = "order"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$order.key] {
            try order.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
