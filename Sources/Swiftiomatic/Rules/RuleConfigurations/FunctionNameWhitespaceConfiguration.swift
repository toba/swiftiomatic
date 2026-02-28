struct FunctionNameWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "generic_spacing")
    private(set) var genericSpacing = GenericSpacingType.noSpace

    enum GenericSpacingType: String, AcceptableByConfigurationElement {
        case noSpace = "no_space"
        case leadingSpace = "leading_space"
        case trailingSpace = "trailing_space"
        case leadingTrailingSpace = "leading_trailing_space"

        var beforeGenericViolationReason: String {
            switch self {
            case .noSpace, .trailingSpace:
                "Superfluous space between function name and generic parameter(s)"
            case .leadingSpace, .leadingTrailingSpace:
                "Missing space between function name and generic parameter(s)"
            }
        }

        var afterGenericViolationReason: String {
            switch self {
            case .noSpace, .leadingSpace:
                "Superfluous space after generic parameter(s)"
            case .trailingSpace, .leadingTrailingSpace:
                "Missing space after generic parameter(s)"
            }
        }
    }

    typealias Parent = FunctionNameWhitespaceRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $genericSpacing.key.isEmpty {
            $genericSpacing.key = "generic_spacing"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$genericSpacing.key] {
            try genericSpacing.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
