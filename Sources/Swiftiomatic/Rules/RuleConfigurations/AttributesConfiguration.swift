
struct AttributesConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "attributes_with_arguments_always_on_line_above")
    private(set) var attributesWithArgumentsAlwaysOnNewLine = true
    @ConfigurationElement(key: "always_on_same_line")
    private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
    @ConfigurationElement(key: "always_on_line_above")
    private(set) var alwaysOnNewLine = Set<String>()
    typealias Parent = AttributesRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $attributesWithArgumentsAlwaysOnNewLine.key.isEmpty {
            $attributesWithArgumentsAlwaysOnNewLine.key = "attributes_with_arguments_always_on_line_above"
        }
        if $alwaysOnSameLine.key.isEmpty {
            $alwaysOnSameLine.key = "always_on_same_line"
        }
        if $alwaysOnNewLine.key.isEmpty {
            $alwaysOnNewLine.key = "always_on_line_above"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$attributesWithArgumentsAlwaysOnNewLine.key] {
            try attributesWithArgumentsAlwaysOnNewLine.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$alwaysOnSameLine.key] {
            try alwaysOnSameLine.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$alwaysOnNewLine.key] {
            try alwaysOnNewLine.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
