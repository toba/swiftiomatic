import Foundation

struct FileNameOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "excluded")
  private(set) var excluded = Set(["main.swift", "LinuxMain.swift"])
  @OptionElement(key: "excluded_paths")
  private(set) var excludedPaths = Set<CachedRegex>()
  @OptionElement(key: "prefix_pattern")
  private(set) var prefixPattern = ""
  @OptionElement(key: "suffix_pattern")
  private(set) var suffixPattern = "\\+.*"
  @OptionElement(key: "nested_type_separator")
  private(set) var nestedTypeSeparator = "."
  @OptionElement(key: "require_fully_qualified_names")
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

extension FileNameOptions {
  func shouldExclude(filePath: String) -> Bool {
    let fileName = (filePath as NSString).lastPathComponent
    if excluded.contains(fileName) {
      return true
    }
    return excludedPaths.contains { $0.hasMatch(in: filePath) }
  }
}
