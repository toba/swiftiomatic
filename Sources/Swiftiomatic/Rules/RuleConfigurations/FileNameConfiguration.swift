import Foundation

struct FileNameConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = Set(["main.swift", "LinuxMain.swift"])
    @ConfigurationElement(key: "excluded_paths")
    private(set) var excludedPaths = Set<RegularExpression>()
    @ConfigurationElement(key: "prefix_pattern")
    private(set) var prefixPattern = ""
    @ConfigurationElement(key: "suffix_pattern")
    private(set) var suffixPattern = "\\+.*"
    @ConfigurationElement(key: "nested_type_separator")
    private(set) var nestedTypeSeparator = "."
    @ConfigurationElement(key: "require_fully_qualified_names")
    private(set) var requireFullyQualifiedNames = false
    typealias Parent = FileNameRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $excluded.key.isEmpty {
            $excluded.key = "excluded"
        }
        if $excludedPaths.key.isEmpty {
            $excludedPaths.key = "excluded_paths"
        }
        if $prefixPattern.key.isEmpty {
            $prefixPattern.key = "prefix_pattern"
        }
        if $suffixPattern.key.isEmpty {
            $suffixPattern.key = "suffix_pattern"
        }
        if $nestedTypeSeparator.key.isEmpty {
            $nestedTypeSeparator.key = "nested_type_separator"
        }
        if $requireFullyQualifiedNames.key.isEmpty {
            $requireFullyQualifiedNames.key = "require_fully_qualified_names"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$excluded.key] {
            try excluded.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$excludedPaths.key] {
            try excludedPaths.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$prefixPattern.key] {
            try prefixPattern.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$suffixPattern.key] {
            try suffixPattern.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$nestedTypeSeparator.key] {
            try nestedTypeSeparator.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$requireFullyQualifiedNames.key] {
            try requireFullyQualifiedNames.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}

extension FileNameConfiguration {
    func shouldExclude(filePath: String) -> Bool {
        let fileName = filePath.bridge().lastPathComponent
        if excluded.contains(fileName) {
            return true
        }
        return excludedPaths.contains { $0.hasMatch(in: filePath) }
    }
}
