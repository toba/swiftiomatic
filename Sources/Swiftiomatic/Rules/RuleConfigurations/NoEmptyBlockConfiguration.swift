
struct NoEmptyBlockConfiguration: SeverityBasedRuleConfiguration {
    enum CodeBlockType: String, AcceptableByConfigurationElement, CaseIterable {
        case functionBodies = "function_bodies"
        case initializerBodies = "initializer_bodies"
        case statementBlocks = "statement_blocks"
        case closureBlocks = "closure_blocks"

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "disabled_block_types")
    private(set) var disabledBlockTypes: [CodeBlockType] = []

    var enabledBlockTypes: Set<CodeBlockType> {
        CodeBlockType.all.subtracting(disabledBlockTypes)
    }
    typealias Parent = NoEmptyBlockRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $disabledBlockTypes.key.isEmpty {
            $disabledBlockTypes.key = "disabled_block_types"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$disabledBlockTypes.key] {
            try disabledBlockTypes.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
