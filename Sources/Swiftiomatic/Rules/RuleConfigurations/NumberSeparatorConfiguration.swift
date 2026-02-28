
struct NumberSeparatorConfiguration: SeverityBasedRuleConfiguration {
    struct ExcludeRange: AcceptableByConfigurationElement, Equatable {
        private let min: Double
        private let max: Double

        func asOption() -> OptionType {
            .symbol("\(min) ..< \(max)")
        }

        init(fromAny value: Any, context ruleID: String) throws(Issue) {
            guard let values = value as? [String: Any],
                  let min = values["min"] as? Double,
                  let max = values["max"] as? Double else {
                throw .invalidConfiguration(ruleID: ruleID)
            }
            self.min = min
            self.max = max
        }

        func contains(_ value: Double) -> Bool {
            min <= value && value < max
        }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "minimum_length")
    private(set) var minimumLength = 0
    @ConfigurationElement(key: "minimum_fraction_length")
    private(set) var minimumFractionLength: Int?
    @ConfigurationElement(key: "exclude_ranges")
    private(set) var excludeRanges = [ExcludeRange]()
    typealias Parent = NumberSeparatorRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $minimumLength.key.isEmpty {
            $minimumLength.key = "minimum_length"
        }
        if $minimumFractionLength.key.isEmpty {
            $minimumFractionLength.key = "minimum_fraction_length"
        }
        if $excludeRanges.key.isEmpty {
            $excludeRanges.key = "exclude_ranges"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$minimumLength.key] {
            try minimumLength.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$minimumFractionLength.key] {
            try minimumFractionLength.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$excludeRanges.key] {
            try excludeRanges.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
