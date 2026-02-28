
typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<DiscouragedObjectLiteralRule>

struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "image_literal")
    private(set) var imageLiteral = true
    @ConfigurationElement(key: "color_literal")
    private(set) var colorLiteral = true
    mutating func apply(configuration: Any) throws(Issue) {
        if $imageLiteral.key.isEmpty {
            $imageLiteral.key = "image_literal"
        }
        if $colorLiteral.key.isEmpty {
            $colorLiteral.key = "color_literal"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$imageLiteral.key] {
            try imageLiteral.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$colorLiteral.key] {
            try colorLiteral.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
