
struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration {
    private static let defaultIndentationWidth = 4

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(
        key: "indentation_width",
        postprocessor: {
            if $0 < 1 {
                Issue.invalidConfiguration(ruleID: Parent.identifier).print()
                $0 = Self.defaultIndentationWidth
            }
        }
    )
    private(set) var indentationWidth = 4
    @ConfigurationElement(key: "include_comments")
    private(set) var includeComments = true
    @ConfigurationElement(key: "include_compiler_directives")
    private(set) var includeCompilerDirectives = true
    @ConfigurationElement(key: "include_multiline_strings")
    private(set) var includeMultilineStrings = true
    typealias Parent = IndentationWidthRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $indentationWidth.key.isEmpty {
            $indentationWidth.key = "indentation_width"
        }
        if $includeComments.key.isEmpty {
            $includeComments.key = "include_comments"
        }
        if $includeCompilerDirectives.key.isEmpty {
            $includeCompilerDirectives.key = "include_compiler_directives"
        }
        if $includeMultilineStrings.key.isEmpty {
            $includeMultilineStrings.key = "include_multiline_strings"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$indentationWidth.key] {
            try indentationWidth.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$includeComments.key] {
            try includeComments.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$includeCompilerDirectives.key] {
            try includeCompilerDirectives.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$includeMultilineStrings.key] {
            try includeMultilineStrings.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
