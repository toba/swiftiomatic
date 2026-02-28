
struct LineLengthConfiguration: RuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 120, error: 200)
    @ConfigurationElement(key: "ignores_urls")
    private(set) var ignoresURLs = false
    @ConfigurationElement(key: "ignores_function_declarations")
    private(set) var ignoresFunctionDeclarations = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = false
    @ConfigurationElement(key: "ignores_interpolated_strings")
    private(set) var ignoresInterpolatedStrings = false
    @ConfigurationElement(key: "ignores_multiline_strings")
    private(set) var ignoresMultilineStrings = false
    @ConfigurationElement(key: "ignores_regex_literals")
    private(set) var ignoresRegexLiterals = false
    @ConfigurationElement(key: "excluded_lines_patterns")
    private(set) var excludedLinesPatterns: Set<String> = []

    var params: [RuleParameter<Int>] {
        length.params
    }
    typealias Parent = LineLengthRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoresURLs.key.isEmpty {
            $ignoresURLs.key = "ignores_urls"
        }
        if $ignoresFunctionDeclarations.key.isEmpty {
            $ignoresFunctionDeclarations.key = "ignores_function_declarations"
        }
        if $ignoresComments.key.isEmpty {
            $ignoresComments.key = "ignores_comments"
        }
        if $ignoresInterpolatedStrings.key.isEmpty {
            $ignoresInterpolatedStrings.key = "ignores_interpolated_strings"
        }
        if $ignoresMultilineStrings.key.isEmpty {
            $ignoresMultilineStrings.key = "ignores_multiline_strings"
        }
        if $ignoresRegexLiterals.key.isEmpty {
            $ignoresRegexLiterals.key = "ignores_regex_literals"
        }
        if $excludedLinesPatterns.key.isEmpty {
            $excludedLinesPatterns.key = "excluded_lines_patterns"
        }
        do {
            try length.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoresURLs.key] {
            try ignoresURLs.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresFunctionDeclarations.key] {
            try ignoresFunctionDeclarations.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresComments.key] {
            try ignoresComments.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresInterpolatedStrings.key] {
            try ignoresInterpolatedStrings.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresMultilineStrings.key] {
            try ignoresMultilineStrings.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresRegexLiterals.key] {
            try ignoresRegexLiterals.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$excludedLinesPatterns.key] {
            try excludedLinesPatterns.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
