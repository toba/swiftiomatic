struct AttributesConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "attributes_with_arguments_always_on_line_above")
  private(set) var attributesWithArgumentsAlwaysOnNewLine = true
  @ConfigurationElement(key: "always_on_same_line")
  private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
  @ConfigurationElement(key: "always_on_line_above")
  private(set) var alwaysOnNewLine = Set<String>()
  typealias Parent = AttributesRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$attributesWithArgumentsAlwaysOnNewLine.key] {
      try attributesWithArgumentsAlwaysOnNewLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysOnSameLine.key] {
      try alwaysOnSameLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysOnNewLine.key] {
      try alwaysOnNewLine.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
