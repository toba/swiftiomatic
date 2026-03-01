import Foundation

struct FileNameConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "excluded")
  private(set) var excluded = Set(["main.swift", "LinuxMain.swift"])
  @ConfigurationElement(key: "excluded_paths")
  private(set) var excludedPaths = Set<CachedRegex>()
  @ConfigurationElement(key: "prefix_pattern")
  private(set) var prefixPattern = ""
  @ConfigurationElement(key: "suffix_pattern")
  private(set) var suffixPattern = "\\+.*"
  @ConfigurationElement(key: "nested_type_separator")
  private(set) var nestedTypeSeparator = "."
  @ConfigurationElement(key: "require_fully_qualified_names")
  private(set) var requireFullyQualifiedNames = false
  typealias Parent = FileNameRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
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
    warnAboutUnknownKeys(in: configuration)
    validate()
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
